//
//  LegalDocuments.swift
//  拾忆
//
//  所有法律文档的内容定义 — 集中管理，方便审阅 / 比对历史版本
//

import Foundation

enum LegalDocuments {

    // MARK: - 隐私协议

    static let privacy = LegalDocument(
        title: "隐私协议",
        lastUpdated: "2026 年 6 月 14 日",
        sections: [
            .init(
                heading: "我们的承诺",
                body: [
                    .emphasis("拾忆 MVP 阶段默认采用纯本地存储，不上传你的数据。"),
                    .paragraph("我们设计这款 App 的首要原则是：你的记忆属于你自己。除非你主动开启云同步并明确同意条款，否则你的文字、照片、定位、人物标签都只保存在本机。")
                ]
            ),
            .init(
                heading: "我们收集什么",
                body: [
                    .paragraph("拾忆运行时需要访问以下信息，所有数据均仅在本机处理："),
                    .bullet([
                        "位置：用于在记录时自动获取当前 POI（如：星巴克·国贸店）",
                        "通讯录：用于「和谁在一起」标签关联（仅读取你选中的联系人）",
                        "麦克风：用于语音转文字识别",
                        "相册 / 相机：用于挂载照片或视频附件",
                        "通知：用于「那年今日」等本地推送提醒"
                    ]),
                    .paragraph("我们不会主动收集你的设备标识符、广告 ID、IP 地址、行为画像等信息。")
                ]
            ),
            .init(
                heading: "数据存储",
                body: [
                    .paragraph("默认情况下，你的所有记忆都存储在 App 沙盒中，受 iOS 系统加密保护。卸载 App 即可彻底删除。"),
                    .paragraph("拾忆会对你挂载的照片与视频进行**本地压缩**后存储：照片重采样为长边不超过 2048 像素的 JPEG（视觉接近无损，体积约为原图三分之一），视频转为 720p 并截取前 30 秒。原图不会被读取保留，也不会上传到任何拾忆服务器。"),
                    .paragraph("若你主动开启 iCloud 同步，记忆会通过 Apple 提供的 CloudKit 通道传输到你 Apple ID 的私有数据库。拾忆开发者无法访问这些数据。"),
                    .emphasis("图片附件可在云同步设置中单独开启同步（视频暂不上传，体积过大）。媒体的开关与主同步开关独立，可随时关闭。")
                ]
            ),
            .init(
                heading: "第三方服务",
                body: [
                    .paragraph("拾忆可选地接入以下服务："),
                    .bullet([
                        "微信开放平台 SDK：仅当你点击「微信登录」或「分享到微信」时启用，遵循腾讯隐私政策",
                        "Apple CloudKit：仅当你开启云同步时启用，遵循 Apple 隐私政策",
                        "Apple 推送服务：用于本地通知（不通过远程服务器，无需 token 注册）"
                    ]),
                    .paragraph("我们不会将你的记忆数据发送给上述任何第三方。")
                ]
            ),
            .init(
                heading: "你的权利",
                body: [
                    .bullet([
                        "随时关闭任意权限：在系统「设置 → 拾忆」中调整",
                        "导出你的所有数据：「我的 → 数据导出」一键导出 Markdown 或 PDF",
                        "彻底删除：删除 App 即可清空本机数据；iCloud 副本可在系统设置「管理储存空间」中删除",
                        "撤回云同步授权：「我的 → 云同步设置 → 撤回授权」"
                    ])
                ]
            ),
            .init(
                heading: "未成年人",
                body: [
                    .paragraph("若你尚未成年，请在监护人陪同下使用本 App，并谨慎决定是否开启云同步等涉及上传的功能。")
                ]
            ),
            .init(
                heading: "联系我们",
                body: [
                    .paragraph("如对本协议有任何疑问，可通过 App Store 评价区或 GitHub Issues 联系开发团队。"),
                    .paragraph("本协议会随产品迭代修订；重大变更我们会在 App 内显著提示。")
                ]
            )
        ]
    )

    // MARK: - 用户协议

    static let terms = LegalDocument(
        title: "用户协议",
        lastUpdated: "2026 年 6 月 14 日",
        sections: [
            .init(
                heading: "服务说明",
                body: [
                    .paragraph("拾忆是一款基于 iOS 的个人记忆记录工具，由开发团队免费提供给用户使用。"),
                    .paragraph("通过下载、安装或使用本 App，即视为你已阅读、理解并同意本协议全部条款。")
                ]
            ),
            .init(
                heading: "使用规范",
                body: [
                    .paragraph("你承诺合法、合理地使用拾忆，不得："),
                    .bullet([
                        "用本 App 记录、储存或分享违反法律法规的内容",
                        "试图绕过 App 的安全机制、反编译或未授权修改",
                        "将本 App 用于商业目的而未取得书面授权",
                        "干扰其他用户的正常使用，或滥用本 App 的网络/计算资源"
                    ])
                ]
            ),
            .init(
                heading: "内容归属",
                body: [
                    .emphasis("你创作的所有记忆内容（文字、照片、视频等）的著作权属于你本人。"),
                    .paragraph("拾忆不会主张对你的内容的任何权利，也不会未经允许将你的内容用于宣传、推广或转售。")
                ]
            ),
            .init(
                heading: "免责声明",
                body: [
                    .paragraph("拾忆按「现状」提供，开发团队尽力保障稳定运行，但不对以下情况负责："),
                    .bullet([
                        "因系统故障、设备损坏、未启用云同步等原因导致的数据丢失",
                        "因 iCloud / 微信 / 高德等第三方服务变更或中断造成的功能不可用",
                        "因网络问题导致的同步延迟或失败"
                    ]),
                    .emphasis("请定期通过「数据导出」备份你的重要记忆。")
                ]
            ),
            .init(
                heading: "服务变更",
                body: [
                    .paragraph("我们保留在不另行通知的情况下变更、暂停或终止部分功能的权利。但我们承诺：在终止前会提供至少 30 天的过渡期，并提供完整的数据导出能力。")
                ]
            ),
            .init(
                heading: "适用法律",
                body: [
                    .paragraph("本协议的解释与执行适用中华人民共和国法律。如有争议，双方应友好协商；协商不成的，提交开发者所在地人民法院管辖。")
                ]
            )
        ]
    )

    // MARK: - 第三方致谢

    static let acknowledgements = LegalDocument(
        title: "第三方致谢",
        lastUpdated: "2026 年 6 月 14 日",
        sections: [
            .init(
                heading: "Apple 框架",
                body: [
                    .bullet([
                        "SwiftUI / SwiftData / WidgetKit / MapKit / PhotosUI / Speech / Contacts / CloudKit / UserNotifications",
                        "上述均为 Apple 公司提供的官方框架，遵循 Apple 平台开发协议。"
                    ])
                ]
            ),
            .init(
                heading: "可选第三方 SDK",
                body: [
                    .bullet([
                        "WechatOpenSDK：腾讯公司开放平台提供，用于微信登录与分享。仅在用户启用相关功能时加载。",
                        "高德地图 iOS SDK（规划中）：高德软件有限公司提供，用于增强国内 POI 反编译精度。"
                    ])
                ]
            ),
            .init(
                heading: "工具与字体",
                body: [
                    .bullet([
                        "XcodeGen：Yonas Kolb，MIT License，用于生成 .xcodeproj",
                        "SF Symbols：Apple 系统图标，遵循 Apple SF Symbols License",
                        "PingFang SC / 苹方：iOS 内置中文字体"
                    ])
                ]
            ),
            .init(
                heading: "灵感来源",
                body: [
                    .paragraph("感谢 Apple 备忘录、Flomo、Day One 等优秀的笔记类产品给予的灵感。拾忆希望在它们的基础上探索属于自己的记录方式。")
                ]
            )
        ]
    )
}
