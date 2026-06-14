//
//  WeChatService.swift
//  拾忆
//
//  微信开放平台 SDK 封装 — 注册 / 登录 / 分享 / URL 回调
//
//  集成步骤（macOS 端）：
//  1. 在 https://open.weixin.qq.com 申请「移动应用」，拿到 AppID
//  2. 在 Apple Developer 后台为 Bundle ID 配置 Universal Link，并把 Universal Link
//     填到微信开放平台后台
//  3. 通过 SPM / CocoaPods 引入 WechatOpenSDK：
//     - SPM:    https://github.com/Tencent/WeChatOpenSDK-Swift
//     - Pod:    pod 'WechatOpenSDK_XCFramework'
//  4. 在 project.yml 把 wxYOUR_WECHAT_APP_ID 替换为真实 AppID
//  5. 在 RecallingMemoriesApp.init 中调用 WeChatService.register()
//

import Foundation
import UIKit

#if canImport(WechatOpenSDK)
import WechatOpenSDK
#endif

@MainActor
final class WeChatService: NSObject, ObservableObject {
    static let shared = WeChatService()

    /// 微信开放平台 AppID — 从 Info.plist 读取以便配置一处生效
    static var appID: String {
        Bundle.main.object(forInfoDictionaryKey: "WeChatAppID") as? String ?? "wxYOUR_WECHAT_APP_ID"
    }

    /// Universal Link — 微信回调用，必须与开放平台后台一致
    static var universalLink: String {
        Bundle.main.object(forInfoDictionaryKey: "WeChatUniversalLink") as? String ?? ""
    }

    /// 当前登录态（拿到的 code 由后端换 access_token，这里仅暴露 code）
    @Published private(set) var lastAuthCode: String?

    /// 登出 — 仅清空本地登录态；接入后端后需追加调后端清账号
    func signOut() {
        lastAuthCode = nil
    }

    /// 微信是否安装
    var isWeChatInstalled: Bool {
        #if canImport(WechatOpenSDK)
        return WXApi.isWXAppInstalled()
        #else
        return false
        #endif
    }

    /// 等待 auth 回调的 continuation（仅一次性使用）
    private var authContinuation: CheckedContinuation<String, Error>?
    /// 等待 share 回调
    private var shareContinuation: CheckedContinuation<Bool, Never>?

    // MARK: - 注册

    /// 在 App 启动时调用一次
    static func register() {
        #if canImport(WechatOpenSDK)
        WXApi.registerApp(appID, universalLink: universalLink)
        #else
        print("[WeChat] SDK 未集成（占位实现）")
        #endif
    }

    // MARK: - 登录

    /// 微信登录 — 返回开放平台 code，由后端换 access_token / openid
    func authLogin() async throws -> String {
        #if canImport(WechatOpenSDK)
        guard isWeChatInstalled else {
            throw WeChatError.notInstalled
        }
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
            self.authContinuation = cont
            let req = SendAuthReq()
            req.scope = "snsapi_userinfo"
            req.state = UUID().uuidString
            WXApi.send(req) { success in
                if !success {
                    self.authContinuation?.resume(throwing: WeChatError.sendFailed)
                    self.authContinuation = nil
                }
            }
        }
        #else
        throw WeChatError.sdkUnavailable
        #endif
    }

    // MARK: - 分享

    /// 分享图片 — 返回是否发送成功（用户取消也算 false）
    func shareImage(_ image: UIImage, scene: SharingScene) async -> Bool {
        #if canImport(WechatOpenSDK)
        guard isWeChatInstalled else { return false }
        return await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            self.shareContinuation = cont

            let media = WXImageObject()
            media.imageData = image.jpegData(compressionQuality: 0.9)

            let message = WXMediaMessage()
            message.mediaObject = media
            // 缩略图（微信要求 ≤ 32KB）
            if let thumb = image.thumbnail(maxBytes: 32 * 1024) {
                message.thumbData = thumb.jpegData(compressionQuality: 0.7)
            }

            let req = SendMessageToWXReq()
            req.bText = false
            req.message = message
            req.scene = Int32(scene.rawValue)

            WXApi.send(req) { success in
                if !success {
                    self.shareContinuation?.resume(returning: false)
                    self.shareContinuation = nil
                }
            }
        }
        #else
        return false
        #endif
    }

    // MARK: - URL / Universal Link 回调

    /// 在 RootView.onOpenURL 里转发
    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        #if canImport(WechatOpenSDK)
        return WXApi.handleOpen(url, delegate: self)
        #else
        return false
        #endif
    }

    /// 在 SwiftUI 的 .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) 里转发
    @discardableResult
    func handleUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        #if canImport(WechatOpenSDK)
        return WXApi.handleOpenUniversalLink(userActivity, delegate: self)
        #else
        return false
        #endif
    }

    enum SharingScene: Int {
        case session = 0   // 好友
        case timeline = 1  // 朋友圈
        case favorite = 2  // 收藏
    }

    enum WeChatError: LocalizedError {
        case notInstalled
        case sendFailed
        case authDenied
        case sdkUnavailable

        var errorDescription: String? {
            switch self {
            case .notInstalled:    return "尚未安装微信"
            case .sendFailed:      return "发送到微信失败"
            case .authDenied:      return "用户拒绝授权"
            case .sdkUnavailable:  return "微信 SDK 未集成"
            }
        }
    }
}

// MARK: - WXApiDelegate

#if canImport(WechatOpenSDK)
extension WeChatService: WXApiDelegate {
    nonisolated func onReq(_ req: BaseReq) {
        // 微信主动唤起 App（如分享回到拾忆等场景），暂无需处理
    }

    nonisolated func onResp(_ resp: BaseResp) {
        Task { @MainActor in
            switch resp {
            case let auth as SendAuthResp:
                if auth.errCode == WXSuccess.rawValue, let code = auth.code {
                    self.lastAuthCode = code
                    self.authContinuation?.resume(returning: code)
                } else {
                    self.authContinuation?.resume(throwing: WeChatError.authDenied)
                }
                self.authContinuation = nil

            case let share as SendMessageToWXResp:
                let ok = share.errCode == WXSuccess.rawValue
                self.shareContinuation?.resume(returning: ok)
                self.shareContinuation = nil

            default:
                break
            }
        }
    }
}
#endif

// MARK: - UIImage 缩略图工具

private extension UIImage {
    /// 把图压缩到目标字节数以内（微信 thumbData ≤ 32KB）
    func thumbnail(maxBytes: Int) -> UIImage? {
        var size = CGSize(width: 200, height: 200)
        var compressed: Data?
        for _ in 0..<5 {
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            self.draw(in: CGRect(origin: .zero, size: size))
            let small = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            if let data = small?.jpegData(compressionQuality: 0.7), data.count <= maxBytes {
                compressed = data
                return small
            }
            size = CGSize(width: size.width * 0.7, height: size.height * 0.7)
        }
        if let data = compressed, let img = UIImage(data: data) { return img }
        return self
    }
}
