# 运行与发布指南

> 本文档面向**首次拿到仓库的工程师**或**Mac 端首次构建**的场景。
> 假设你正在一台 macOS 14+ 的设备上，已安装 Xcode 15+。

---

## 0. 前置确认

| 项 | 最低 |
|---|---|
| macOS | 14 (Sonoma) |
| Xcode | 15 |
| iOS Deployment | 17.0 |
| Swift | 5.9 |
| 真机调试 | 推荐，模拟器无法测微信/Widget/CloudKit |
| Apple Developer 账号 | TestFlight / 真机均需要 |

---

## 1. 把仓库拉到 Mac

```bash
git clone <你的仓库地址> RecallingMemories
cd RecallingMemories
```

仓库初始环境是 Windows，文件大概率会有 CRLF 行尾。Xcode 能正确解析，但若想强制对齐：

```bash
git config core.autocrlf input
git rm --cached -r .
git reset --hard
```

---

## 2. 生成 Xcode 工程

仓库**不提交 `.xcodeproj`**，由 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 从 `project.yml` 生成。

```bash
brew install xcodegen
xcodegen generate
open RecallingMemories.xcodeproj
```

生成的工程包含 2 个 target：
- `RecallingMemories` — 主 App
- `RecallingMemoriesWidget` — 桌面小组件

---

## 3. 修改占位

`project.yml` 中三处需要替换为真实值：

```yaml
DEVELOPMENT_TEAM: ""              # 填 Apple Developer Team ID
WeChatAppID: wxYOUR_WECHAT_APP_ID # 微信开放平台 AppID（不接微信可保留占位）
WeChatUniversalLink: https://your.universal.link/wechat/  # 同上
```

`CFBundleURLSchemes` 段中的 `wxYOUR_WECHAT_APP_ID` 也要同步替换。

修改后重新执行：

```bash
xcodegen generate
```

> ⚠️ **不要直接在 Xcode 里改这些字段** —— `.xcodeproj` 是生成产物，下次 `xcodegen` 会覆盖。

---

## 4. 配置 Capabilities

打开 Xcode → 选中 `RecallingMemories` target → **Signing & Capabilities**：

### Signing
- Team：选你的开发者团队
- Bundle Identifier：`com.recallingmemories.app`
- Provisioning：自动管理（推荐）

### App Groups
- 已通过 entitlements 自动声明：`group.com.recallingmemories.app`
- 在 Apple Developer 后台 **Identifiers → App Groups** 创建同名 group，并 **Edit** Bundle ID 把 group 勾上

### iCloud
- 勾选 **CloudKit**
- Container：`iCloud.com.recallingmemories.app`（首次会提示创建）

### Associated Domains（仅接微信时需要）
- `applinks:your.universal.link.host`（与 `WeChatUniversalLink` 同域）
- 你的域名根目录需托管 `.well-known/apple-app-site-association`，详见 `docs/wechat-integration.md`

### Widget Target
- 选中 `RecallingMemoriesWidget` target → 同样勾上 App Groups（同名 group）
- Bundle Identifier：`com.recallingmemories.app.widget`

---

## 5. 引入第三方依赖（可选）

### 微信 SDK（不接可跳过）

代码用 `#if canImport(WechatOpenSDK)` 包裹，未引入时自动降级为「保存到相册 + 系统分享面板」。

**SPM 引入**（推荐）：

```
File → Add Packages…
URL: https://github.com/Tencent/WeChatOpenSDK-Swift
```

引入后无需改代码，重新 build 即可。详细步骤见 `docs/wechat-integration.md`。

### 高德地图 SDK（不接可跳过）

产品文档里规划用高德 SDK 做 POI 反编译；当前实现仅用 Apple 自带的 `CLGeocoder`，对国内 POI 精度有限但能跑。需要时再接。

---

## 6. 真机首次运行

1. iPhone 用数据线连 Mac，解锁手机
2. 在手机上 **设置 → 通用 → VPN 与设备管理** → 信任此开发者
3. Xcode 顶部 device 选择真机
4. ⌘R 运行

首次运行会看到：
1. **首屏引导** —— 4 页介绍核心价值
2. 完成引导 → 默认 record Tab，输入框已聚焦

---

## 7. 验证关键能力

| 功能 | 验证步骤 | 期望 |
|---|---|---|
| 极速记录 | 录入文字 → 保存 → 切到「时光」 | 时光页出现该条 |
| 定位 | 首次保存时允许位置权限 → 看时光卡片 | footer 出现「📍 POI 名称」 |
| 媒体 | 工具条「📷」选 1-2 张图 | 缩略图条出现，时光页缩略图网格出现 |
| 语音 | 长按麦克风允许权限 → 说话 → 停止 | 文字自动拼到草稿 |
| 人物 | 工具条「👥」→ 通讯录授权 → 选人 | 上方 capsule 显示已选人物 |
| 那年今日 | 在时光页删一条改成去年同日的记忆<sup>*</sup> | 我的→那年今日 出现 |
| 推送 | 我的→通知 开启 + 选时间 | 系统设置中出现拾忆推送权限项 |
| 搜索 | 时光页右上🔍 → 输入关键词 | 高亮显示匹配结果 |
| 地图 | 切到「足迹」Tab | 图钉出现，点击弹底部记忆列表 |
| Widget | 主屏长按 → 添加小组件 → 拾忆 | 「快速记录」「那年今日」可选 |
| 分享 | 详情→↑ → 选模板 → 保存到相册 | 相册多出 1080×1440 卡片 |
| 数据导出 | 我的→数据导出 → PDF → 生成 | 系统分享面板出现 PDF 文件 |
| 云同步 | 我的→云同步设置 → 开关 → 同意条款 | 重启 App，时光数据未丢 |
| 引导重看 | 我的→关于→重新查看引导 → 重启 | 又看到 4 页引导 |

<sup>*</sup> 因为「那年今日」要求历史上同月同日存在记录，新装设备上立即看不到，需手动调时间或等一年。

---

## 8. TestFlight 发布

1. **App Store Connect** 创建应用
   - Bundle ID：`com.recallingmemories.app`
   - Primary Language：Simplified Chinese

2. **Archive 打包**
   - Xcode 顶部 device 选 **Any iOS Device**
   - Product → Archive
   - Organizer → Distribute App → App Store Connect → Upload

3. **填提审材料**（首次）
   - 隐私问题：
     - 位置（可选）：`记忆位置定位`
     - 通讯录（可选）：`人物标签关联`
     - 麦克风（可选）：`语音转文字`
     - 相机/相册（必需）：`记忆媒体附件`
     - 推送通知（必需）：`那年今日提醒`
     - 用户内容关联标识符：是（关联到 iCloud 用户）
   - 加密导出合规：使用标准加密（HTTPS / Apple 提供的加密通讯）

4. **TestFlight**
   - 内部测试组：100 人，立即可用
   - 外部测试组：≤ 10000 人，首次需 Apple 审核（1-3 天）

---

## 9. 常见坑

| 现象 | 排查 |
|---|---|
| `xcodegen: command not found` | `brew install xcodegen` |
| 构建报 `iCloud Container does not exist` | 在 Apple Developer 后台先创建 Container `iCloud.com.recallingmemories.app` |
| Widget 不刷新 | 主 App 必须有数据写入触发 `WidgetSnapshotPublisher.publish`；首次安装空 Widget 是正常的 |
| 微信无法回调 | Universal Link 域名 JSON 必须可公网访问 + 重启手机让系统重新拉取 association 文件 |
| CloudKit 同步不生效 | 检查 iCloud 账号已登录、CloudKit Dashboard 中 Schema 已 Promote 到 Production |
| Preview 崩溃 | 重启 Xcode，删 `~/Library/Developer/Xcode/DerivedData/` |
| 真机连不上 | 数据线换原装 / 重连 / 关闭 iPhone 锁屏 |
| 行尾警告刷屏 | `git config core.autocrlf input` 后重新 clone |

---

## 10. 调试小技巧

```swift
// 重置引导（已有 UI 入口：我的→关于→重新查看引导）
OnboardingService.shared.reset()

// 强制刷新 Widget 快照
WidgetSnapshotPublisher.publish(modelContainer: modelContainer)

// 清除「那年今日」推送排程
UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

// 切换云同步模式（需重启 App）
UserDefaults.standard.set(true, forKey: "RM.cloudSync.enabled")
UserDefaults.standard.set(Date(), forKey: "RM.cloudSync.agreedAt")
```

清理本地数据库（仅限调试）：
```bash
xcrun simctl get_app_container booted com.recallingmemories.app data
# rm -rf 该目录
```

---

## 11. 代码地图

```
RecallingMemories/
├── App/                  # @main + AppRouter
├── Models/               # Memory / Person (SwiftData @Model)
├── Services/             # 单例服务层
│   ├── LocationService          - CoreLocation
│   ├── SpeechService            - Speech Framework
│   ├── ContactsService          - Contacts
│   ├── NotificationService      - 那年今日推送排程
│   ├── WeChatService            - 微信 SDK 适配（条件编译）
│   ├── CloudSyncService         - iCloud / 本地切换
│   ├── OnboardingService        - 引导版本控制
│   ├── WidgetSnapshotPublisher  - 主 App 推快照给 Widget
│   ├── AttachmentStore          - 媒体落盘
│   ├── ShareCardRenderer        - 朋友圈卡片渲染
│   ├── MarkdownExporter         - Markdown 导出
│   ├── PDFExporter              - PDF 时光书
│   ├── MemorySearch             - 多维搜索（纯函数）
│   └── OnThisDayMatcher         - 那年今日匹配（纯函数）
├── Shared/               # Widget 与主 App 共享
│   ├── WidgetShared             - 常量
│   └── WidgetSnapshot           - 跨进程快照模型
├── Views/
│   ├── Onboarding/              - 4 页引导
│   ├── Record/                  - 极速记录页
│   ├── Timeline/                - 时光轴 + 详情
│   ├── Map/                     - 足迹地图 + 聚类
│   ├── Search/                  - 全局搜索
│   ├── OnThisDay/               - 那年今日
│   ├── Profile/                 - 我的（设置/管理）
│   ├── Share/                   - 分享构图器
│   └── Shared/                  - EmptyStateView
└── Resources/            - Info.plist / entitlements

RecallingMemoriesWidget/
├── RecallingMemoriesWidgetBundle  - Widget 入口
├── WidgetSnapshotProvider         - TimelineProvider
├── QuickRecordWidget              - Small/Medium 快速记录
└── OnThisDayWidget                - Medium/Large 那年今日

docs/
└── wechat-integration.md          - 微信 SDK 集成指南
```
