//
//  WeChatService.swift
//  拾忆
//
//  微信开放平台 SDK 封装 — 登录 / 分享卡片
//  TODO: 接入 WXApi (需在 Mac 端通过 SPM/Pods 引入 WechatOpenSDK)
//

import Foundation
import UIKit

enum WeChatService {

    /// 微信开放平台 AppID — 替换为实际申请的 AppID
    static let appID: String = "wxYOUR_WECHAT_APP_ID"

    static func register() {
        // WXApi.registerApp(appID, universalLink: "https://your.universal.link/")
    }

    /// 微信登录
    static func authLogin() async throws -> String {
        // let req = SendAuthReq()
        // req.scope = "snsapi_userinfo"
        // req.state = UUID().uuidString
        // WXApi.send(req)
        // → 通过 AppDelegate handleOpenURL 接收 code
        throw NSError(domain: "WeChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "未接入 WechatOpenSDK"])
    }

    /// 分享图片到朋友圈或好友
    static func shareImage(_ image: UIImage, scene: SharingScene) {
        // let media = WXImageObject()
        // media.imageData = image.pngData()
        // let message = WXMediaMessage(); message.mediaObject = media
        // let req = SendMessageToWXReq(); req.bText = false; req.message = message; req.scene = scene.rawValue
        // WXApi.send(req)
    }

    enum SharingScene: Int {
        case session = 0   // 好友
        case timeline = 1  // 朋友圈
        case favorite = 2  // 收藏
    }
}
