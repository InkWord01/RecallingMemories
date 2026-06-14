//
//  UserManualView.swift
//  拾忆
//
//  操作手册 — 系统介绍每个核心功能怎么用，比帮助中心 FAQ 更结构化
//
//  设计：左侧图标 + 步骤化说明，按业务流程从 0 到 1 走一遍
//

import SwiftUI

struct UserManualView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                ForEach(UserManualView.chapters) { chapter in
                    ChapterView(chapter: chapter)
                }
                footer
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("操作手册")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("从零开始")
                .font(.title2.bold())
            Text("跟着这本手册走一遍，你就掌握了拾忆的全部能力。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("还有问题？")
                .font(.headline)
            Text("到「我的 → 帮助中心」搜索具体场景，或在 App Store 评论区告诉我。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Chapter View

private struct ChapterView: View {
    let chapter: UserManualChapter

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: chapter.icon)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 32, height: 32)
                    .background(.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                Text(chapter.title)
                    .font(.title3.bold())
            }

            if let intro = chapter.intro {
                Text(intro)
                    .font(.body)
                    .foregroundStyle(.primary.opacity(0.85))
                    .lineSpacing(4)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(chapter.steps.enumerated()), id: \.offset) { idx, step in
                    StepRow(index: idx + 1, text: step)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))

            if let tip = chapter.tip {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    Text(tip)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 8)
            }
        }
    }
}

private struct StepRow: View {
    let index: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(.tint, in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - 数据模型

struct UserManualChapter: Identifiable {
    var id: String { title }
    let icon: String
    let title: String
    var intro: String?
    let steps: [String]
    var tip: String?
}

// MARK: - 内容定义

extension UserManualView {

    static let chapters: [UserManualChapter] = [
        UserManualChapter(
            icon: "square.and.pencil",
            title: "记录此刻",
            intro: "拾忆的核心是「打开就能写」。无需新建笔记本、无需选分类，直接落笔。",
            steps: [
                "打开 App，光标已在输入框中等你 — 直接键入想法",
                "想留张照片？点工具栏左下「📷」，从相册选 1-9 张图片或视频",
                "懒得打字？点「🎤」长按说话，识别成文字会自动拼到草稿",
                "想标注「和谁在一起」？点「👥」从通讯录选人，或自定义新建",
                "选一个情绪标签：💡顿悟 / 🔥激动 / 😌平静 / 🌙怅然 / 🌿温柔",
                "点右下「保存」— 时光、地点、附件、人物会自动绑定到这条记忆"
            ],
            tip: "App 启动时会悄悄拿一次定位，只要你给了权限，记忆里的 POI（如：星巴克·国贸店）就会自动出现。"
        ),

        UserManualChapter(
            icon: "list.bullet.rectangle",
            title: "回看时光",
            intro: "所有记忆按日期自动分组。今天 / 昨天 / 本周 / 跨年都有清晰的层次。",
            steps: [
                "切到「时光」Tab，看到按时间分组的卡片流",
                "卡片上能看到时间、情绪、文字摘要、附件缩略图、地点、人物",
                "点击任一条进入详情：完整文本、媒体画廊、人物头像",
                "向左滑卡片可以分享或删除",
                "右上角「🔍」搜索任意关键词、地点、人物、情绪、时间范围"
            ],
            tip: "搜索支持空格分词。「灵感 星巴克」会找出同时含「灵感」和「星巴克」的所有记忆。"
        ),

        UserManualChapter(
            icon: "map",
            title: "在地图上看足迹",
            intro: "每条带定位的记忆都会在地图上显示一个图钉，相近的会自动聚合。",
            steps: [
                "切到「足迹」Tab",
                "圆形图钉显示该位置的记忆数量",
                "点击图钉浮出底部面板，列出此地的所有记忆",
                "点列表中任一条进入详情",
                "右上角「🎯」按钮一键聚焦所有图钉"
            ]
        ),

        UserManualChapter(
            icon: "calendar.badge.clock",
            title: "「那年今日」",
            intro: "拾忆会在每一天，悄悄送回历史上同月同日的回忆。",
            steps: [
                "「我的 → 那年今日」可主动查看今日命中的所有历史记忆",
                "「我的 → 通知与推送」开启「那年今日」回忆推送 + 设置每天提醒时间",
                "推送送达后点击通知，会直接打开对应记忆的详情"
            ],
            tip: "新装设备上没有历史记忆，需要等一年后的同一天才会有内容。所有计算都在本机完成，不上传。"
        ),

        UserManualChapter(
            icon: "square.and.arrow.up",
            title: "分享与导出",
            intro: "拾忆支持把记忆做成精美卡片分享，也支持完整数据导出。",
            steps: [
                "在记忆详情页点右上「↑」打开分享构图器",
                "切换三种模板：极简 / 拍立得 / 卡纸",
                "点「保存到相册」生成 1080×1440 朋友圈卡片",
                "或点「更多」走系统分享面板（含微信、隔空投送等）",
                "想批量备份？「我的 → 数据导出」选 Markdown 单文件 / Markdown 含附件 / PDF 时光书"
            ]
        ),

        UserManualChapter(
            icon: "rectangle.stack",
            title: "桌面小组件",
            intro: "把拾忆挂到主屏，记录入口和回忆推送随时可见。",
            steps: [
                "长按主屏空白处进入抖动模式",
                "左上角加号 → 搜索「拾忆」",
                "「快速记录」（小/中尺寸）— 一键打开记录页 + 显示最近一条",
                "「那年今日」（中/大尺寸）— 直接显示历史同日记忆，点击进入详情"
            ]
        ),

        UserManualChapter(
            icon: "icloud",
            title: "云同步（可选）",
            intro: "默认所有数据都在本机。开启 iCloud 同步后，可在所有 Apple 设备间共享。",
            steps: [
                "「我的 → 云同步设置」点击开关",
                "首次开启会弹出隐私须知，请滑到底部阅读完整条款",
                "同意后重启 App 生效（SwiftData 限制）",
                "同步范围：默认仅文字、时间、地点、人物、情绪",
                "想同步图片？再开启「同步图片附件」开关（视频不同步，体积过大）"
            ],
            tip: "拾忆服务器看不到你的数据。所有同步都通过 Apple CloudKit 进入你 Apple ID 的私有数据库。"
        ),

        UserManualChapter(
            icon: "person.2.crop.square.stack",
            title: "管理人物",
            intro: "「和谁在一起」标签会随时间累积，可以编辑、合并重名、清理孤儿。",
            steps: [
                "「我的 → 人物管理」",
                "顶部显示是否有重名条目可合并 / 是否有未关联记忆的孤儿可清理",
                "点击任一条目可改名 / 解除通讯录关联",
                "向左滑可删除（关联的记忆会自动解引用）"
            ]
        )
    ]
}

#Preview {
    NavigationStack { UserManualView() }
}
