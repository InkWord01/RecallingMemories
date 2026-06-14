//
//  HelpCenterView.swift
//  拾忆
//
//  应用内帮助中心 — 把 RUN.md / build-errors.md 的常见问题精炼成 in-app 卡片
//
//  设计原则：
//   1. 用户不需要打开浏览器或 GitHub
//   2. 高频问题排前 + 可搜索
//   3. 「立即修复」按钮直接跳系统设置 / 应用内对应页面
//

import SwiftUI

struct HelpCenterView: View {
    @State private var keyword: String = ""
    @State private var expandedID: UUID?

    private var filtered: [HelpCategory] {
        guard !keyword.isEmpty else { return Self.categories }
        let kw = keyword
        return Self.categories.compactMap { category in
            let items = category.items.filter { item in
                item.question.localizedCaseInsensitiveContains(kw)
                    || item.answer.localizedCaseInsensitiveContains(kw)
            }
            return items.isEmpty ? nil : HelpCategory(title: category.title, icon: category.icon, items: items)
        }
    }

    var body: some View {
        Group {
            if filtered.isEmpty {
                ContentUnavailableView.search(text: keyword)
            } else {
                List {
                    ForEach(filtered, id: \.title) { category in
                        Section {
                            ForEach(category.items) { item in
                                HelpItemRow(
                                    item: item,
                                    isExpanded: expandedID == item.id,
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            expandedID = (expandedID == item.id) ? nil : item.id
                                        }
                                    }
                                )
                            }
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                Text(category.title)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("帮助中心")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $keyword, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "搜索问题")
    }
}

// MARK: - Row

private struct HelpItemRow: View {
    let item: HelpItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 问题行（始终显示）
            Button(action: onTap) {
                HStack(alignment: .top, spacing: 10) {
                    Text("Q")
                        .font(.caption.bold())
                        .foregroundStyle(.tint)
                        .frame(width: 18, height: 18)
                        .background(.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                    Text(item.question)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        Text("A")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 18, height: 18)
                            .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                        Text(item.answer)
                            .font(.body)
                            .foregroundStyle(.primary.opacity(0.85))
                            .lineSpacing(3)
                        Spacer()
                    }

                    // 行动按钮
                    if let action = item.action {
                        Button {
                            action.handler()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: action.icon)
                                Text(action.title)
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.tint, in: Capsule())
                        }
                        .padding(.leading, 28) // 与 A 的内容对齐
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - 数据模型

struct HelpCategory {
    let title: String
    let icon: String
    let items: [HelpItem]
}

struct HelpItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    var action: Action?

    struct Action {
        let title: String
        let icon: String
        let handler: () -> Void
    }
}

// MARK: - 内容定义

extension HelpCenterView {

    static let categories: [HelpCategory] = [
        // 记录相关
        HelpCategory(
            title: "记录",
            icon: "square.and.pencil",
            items: [
                HelpItem(
                    question: "记录时为什么没自动获取到位置？",
                    answer: """
                    需要先授权位置权限。打开后稍等几秒让 GPS 锁定，POI 名称会自动出现在输入区下方。
                    若长期获取不到，可能是室内信号差或系统设置中关闭了「定位服务」。
                    """,
                    action: HelpItem.Action(
                        title: "去系统设置",
                        icon: "gearshape",
                        handler: openAppSettings
                    )
                ),
                HelpItem(
                    question: "语音转文字识别不出我说的话？",
                    answer: """
                    拾忆用 Apple 原生 Speech 框架，识别质量取决于环境噪音和发音清晰度。
                    首次使用需要授权语音识别 + 麦克风权限。中文识别仅在当前语言设置含中文时生效。
                    长按麦克风按钮录音，停止后文字自动拼到草稿。
                    """
                ),
                HelpItem(
                    question: "可以记录多张照片或视频吗？",
                    answer: """
                    点工具栏的相册图标，最多一次挂载 9 张照片或视频。
                    照片会自动压缩到长边 2048 像素以内（视觉接近无损，节省空间），视频会转码为 720p 并截取前 30 秒。
                    原图保留在你的系统相册中不受影响。
                    """
                ),
                HelpItem(
                    question: "「和谁在一起」如何添加新人物？",
                    answer: """
                    点工具栏的人物图标，弹出选择面板。三种来源：
                    · 通讯录：首次使用需授权，会列出所有联系人
                    · 常用：之前添加过的人物
                    · 自定义添加：右上角加号，输入姓名即可（无需通讯录）
                    """
                )
            ]
        ),

        // 那年今日 / 推送
        HelpCategory(
            title: "回忆与推送",
            icon: "calendar.badge.clock",
            items: [
                HelpItem(
                    question: "「那年今日」为什么是空的？",
                    answer: """
                    「那年今日」匹配的是过去同月同日的记忆。新装设备上没有历史，所以是空的。
                    一年后的同一天再来，会看到今天写下的内容。
                    """
                ),
                HelpItem(
                    question: "怎么开启每日定时提醒？",
                    answer: """
                    在「我的 → 通知与推送」中开启「那年今日」回忆推送，并选择每天提醒的时间（默认 9:00）。
                    系统会每天定时扫描历史同日记忆，命中即推送一条提醒。计算全部在本地完成，不上传。
                    """,
                    action: HelpItem.Action(
                        title: "去通知设置",
                        icon: "bell",
                        handler: openAppSettings
                    )
                ),
                HelpItem(
                    question: "推送授权过被拒绝了，怎么重新打开？",
                    answer: """
                    iOS 不允许 App 二次弹授权请求。请到系统设置中手动重新打开。
                    """,
                    action: HelpItem.Action(
                        title: "去系统设置",
                        icon: "gearshape",
                        handler: openAppSettings
                    )
                )
            ]
        ),

        // 数据与同步
        HelpCategory(
            title: "数据与同步",
            icon: "icloud",
            items: [
                HelpItem(
                    question: "拾忆默认会上传我的数据吗？",
                    answer: """
                    不会。MVP 阶段默认纯本地存储。是否上云完全由你决定。
                    若开启云同步，数据走 Apple CloudKit 进入你 Apple ID 的私有数据库，拾忆开发者无法访问。
                    详见隐私协议。
                    """
                ),
                HelpItem(
                    question: "云同步开了之后没看到另一台设备的数据？",
                    answer: """
                    检查这几点：
                    · 两台设备登录的 Apple ID 是否相同
                    · iCloud Drive 已启用
                    · 网络稳定（首次同步可能需要几分钟）
                    · 设备 iOS 版本均 17.0+
                    云同步开关刚切换时需要重启 App 才能生效。
                    """
                ),
                HelpItem(
                    question: "媒体附件（照片 / 视频）会同步吗？",
                    answer: """
                    图片可选择性同步：在「我的 → 云同步设置」中开启「同步图片附件」即可。
                    视频暂不上传（体积过大）；后续版本会探索更高效的视频同步方案。
                    """
                ),
                HelpItem(
                    question: "怎么把所有记忆备份出来？",
                    answer: """
                    「我的 → 数据导出」支持三种格式：
                    · Markdown 单文件：纯文本，体积小，附件不随行
                    · Markdown 含附件：zip 包，附件以相对路径引用，可跨设备打开
                    · PDF 时光书：A4 排版按月分章，适合打印或长期归档
                    """
                ),
                HelpItem(
                    question: "想彻底删除我所有数据怎么办？",
                    answer: """
                    · 删除 App 即可清空本机所有记忆与附件
                    · 若开过云同步，云端副本需要在系统「设置 → Apple ID → iCloud → 管理储存空间 → 拾忆」中手动删除
                    """
                )
            ]
        ),

        // 分享
        HelpCategory(
            title: "分享",
            icon: "square.and.arrow.up",
            items: [
                HelpItem(
                    question: "为什么没有「微信好友 / 朋友圈」按钮？",
                    answer: """
                    这两个按钮只在检测到设备已安装微信时显示。若没装微信，可以用「保存到相册」后手动发到微信，或点「更多」走系统分享面板。
                    """
                ),
                HelpItem(
                    question: "卡片上锁的「Pro」模板是什么？",
                    answer: """
                    Pro 模板正在打磨中，将在后续版本推出。当前可用三种免费模板：极简、拍立得、卡纸。
                    """
                ),
                HelpItem(
                    question: "保存到相册没看到图？",
                    answer: """
                    需要授权「相册添加」权限。若拒绝过，请到系统设置中重新打开。
                    """,
                    action: HelpItem.Action(
                        title: "去系统设置",
                        icon: "gearshape",
                        handler: openAppSettings
                    )
                )
            ]
        ),

        // 桌面小组件
        HelpCategory(
            title: "桌面小组件",
            icon: "rectangle.stack",
            items: [
                HelpItem(
                    question: "怎么把拾忆 Widget 加到主屏？",
                    answer: """
                    长按主屏空白处进入抖动模式 → 左上角加号 → 搜索「拾忆」→ 选择「快速记录」或「那年今日」→ 选尺寸 → 添加。
                    """
                ),
                HelpItem(
                    question: "Widget 显示的是假数据？",
                    answer: """
                    首次添加且主 App 还未保存过任何记忆时，Widget 会展示示例数据让你预览效果。
                    在主 App 里保存第一条记忆后，Widget 会自动刷新成真实数据。
                    """
                ),
                HelpItem(
                    question: "Widget 内容什么时候更新？",
                    answer: """
                    每次主 App 保存或删除记忆都会立即触发 Widget 刷新。除此之外系统会每小时兜底刷一次。
                    若长时间不更新，可以重新长按 Widget → 编辑小组件 → 触发一次重载。
                    """
                )
            ]
        ),

        // 隐私与权限
        HelpCategory(
            title: "隐私与权限",
            icon: "hand.raised.fill",
            items: [
                HelpItem(
                    question: "你们会看到我的记忆内容吗？",
                    answer: """
                    不会。拾忆没有收集服务器，所有内容只在你的设备上处理。即使开启云同步，数据也是经 Apple CloudKit 直接存到你 Apple ID 的私有库，开发者无任何访问权限。
                    详见隐私协议。
                    """
                ),
                HelpItem(
                    question: "通讯录权限关闭后还能用吗？",
                    answer: """
                    可以。「和谁在一起」面板会回退到「自定义添加」模式，你可以手动输入人名作为标签。
                    """
                ),
                HelpItem(
                    question: "怎么查看完整的隐私协议？",
                    answer: """
                    「我的 → 关于 → 隐私协议」可随时查看。重大变更我们会在 App 内显著提示。
                    """
                )
            ]
        )
    ]

    // MARK: - 行动处理

    @MainActor
    static func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationStack { HelpCenterView() }
}
