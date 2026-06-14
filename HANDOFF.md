# 项目交付清单 (HANDOFF)

> 这份文档面向**接手维护**或**继续迭代**拾忆 RecallingMemories 的工程师 / 团队。
> 它不重复 README/RUN.md 已有内容，而是回答两个问题：
> **「这个仓库当前是什么状态？」「下一个版本应该往哪走？」**

最后更新：2026 年 6 月 14 日 · 累计 30 次提交

---

## 目录

1. [一句话总结](#一句话总结)
2. [仓库现状](#仓库现状)
3. [代码结构地图](#代码结构地图)
4. [设计决策与权衡](#设计决策与权衡)
5. [已知遗留与技术债](#已知遗留与技术债)
6. [上线前 Checklist](#上线前-checklist)
7. [迭代路线图建议](#迭代路线图建议)
8. [术语表](#术语表)

---

## 一句话总结

**拾忆是一款"基于时空的灵感与记忆捕捉"iOS App，本仓库已交付 init.txt 规划的全部 Phase 1/2/3 功能，可在 Mac 端 5 分钟内跑通；商业化（Pro 订阅）暂留占位待产品决策。**

---

## 仓库现状

### 体量
| 项 | 数 |
|---|---|
| Git 提交 | 30 |
| Swift 源码文件 | 55（主 App 39 + Widget 4 + Tests 5 + Shared 2 + 余 5） |
| 单元测试用例 | 33+（4 个纯函数模块 + Mood 工具） |
| Markdown 文档 | 8（含 init.txt 产品文档） |
| Targets | 3（主 App / Widget / Tests） |

### 完成度
| Phase | 项目 | 状态 |
|---|---|---|
| **Phase 1 MVP** | 极速记录引擎（文字/语音/图视频/人物） | ✅ |
| | 时空锚点（时间/POI/天气占位/情绪） | ✅ |
| | 记忆重现（时间轴/地图/搜索） | ✅ |
| | 微信生态对接（登录/分享） | ✅ 代码完整，等真实 AppID |
| **Phase 2 体验完善** | 视频录制 | ✅ PhotosPicker |
| | 语音转文字 | ✅ |
| | 地图模式 | ✅ |
| | 桌面小组件 | ✅ Quick Record + 那年今日 |
| **Phase 3 云端商业化** | 云同步（含图片附件） | ✅ |
| | 那年今日推送 | ✅ |
| | 数据导出 | ✅ MD/PDF/zip |
| | Pro 卡片模板 | ⏳ 占位（4 个 Pro case，点击弹"敬请期待"） |
| | 订阅商业化 | ⏳ 待产品决策 |

### 测试 & 质量
- ✅ 5 轮静态自检全部清账（详见 `git log --grep=audit`）
- ✅ CI 双 Job：Ubuntu lint + macOS build/test
- ✅ A11y：VoiceOver 标签 / Dynamic Type / Reduce Motion 已适配
- ✅ 引导流 / 帮助中心 / 隐私协议 / 用户协议 / 第三方致谢 全部真实页面，无 Text 占位

---

## 代码结构地图

```
RecallingMemories/                    主 App（iOS 17+，SwiftUI + SwiftData）
├── App/
│   ├── RecallingMemoriesApp.swift   @main + ModelContainer 构造
│   └── AppRouter.swift              单点路由（通知/Widget/微信回调）
├── Models/                          @Model 层（CloudKit 兼容设计）
│   ├── Memory.swift
│   ├── Person.swift
│   └── Attachment.swift             双写策略：本地路径 + externalStorage Data
├── Services/                        13 个单例
│   ├── 数据层    LocationService / SpeechService / ContactsService
│   │           AttachmentStore / WeChatService / CloudSyncService
│   │           NotificationService / OnboardingService
│   ├── 处理层    WidgetSnapshotPublisher
│   ├── 输出层    ShareCardRenderer / MarkdownExporter / PDFExporter
│   └── 纯函数    MemorySearch / OnThisDayMatcher
├── Shared/                          主 App ↔ Widget 共享
│   ├── WidgetShared.swift          AppGroup ID / Deep Link 常量
│   ├── WidgetSnapshot.swift        跨进程快照模型
│   └── Mood.swift                  情绪标签 + a11y 工具
└── Views/                           SwiftUI 视图（按业务分目录）
    ├── Onboarding/                 4 页引导
    ├── Record/                     极速记录（核心入口）
    ├── Timeline/                   时光轴 + 详情 + 分组
    ├── Map/                        足迹地图 + 聚类
    ├── Search/                     全局多维搜索
    ├── OnThisDay/                  那年今日
    ├── Profile/                    我的（10 个二级页）
    ├── Share/                      分享构图器 + UIActivityViewController
    └── Shared/                     EmptyStateView 通用组件

RecallingMemoriesWidget/             小组件 Extension
├── RecallingMemoriesWidgetBundle   入口
├── WidgetSnapshotProvider          TimelineProvider
├── QuickRecordWidget               Small/Medium 快速记录
└── OnThisDayWidget                 Medium/Large 那年今日

RecallingMemoriesTests/              单元测试
├── TestFactory.swift               In-memory 容器 fixture
├── OnThisDayMatcherTests.swift     6 用例（含闰年 / 未来时间）
├── TimelineGroupingTests.swift     5 用例
├── LocationClusteringTests.swift   6 用例
├── MemorySearchTests.swift         11 用例
└── MoodTests.swift                 5 用例

design/                              SVG 矢量源（仓库唯一图形真相）
├── AppIcon.svg
└── LaunchLogo.svg

tools/
└── generate-icons.sh               macOS 端 SVG → PNG/PDF

docs/
├── build-errors.md                 首次构建 12 + 5 + 5 个错误清单
└── wechat-integration.md           微信 SDK macOS 端集成指南

.github/
├── workflows/ci.yml                双 Job CI
├── PULL_REQUEST_TEMPLATE.md
└── ISSUE_TEMPLATE/                 bug / feature 表单
```

### 模块依赖原则
- **Models 不依赖 UI / Services**
- **Services 内部可互调**（如 RecordViewModel 调 SpeechService + LocationService）
- **纯函数模块**（`MemorySearch` / `OnThisDayMatcher` / `TimelineGrouping` / `LocationClustering`）**不依赖 SwiftData 上下文**，纯输入输出 → 可独立测试

---

## 设计决策与权衡

接手前请理解这些**主动选择**，避免无意中破坏：

### 1. SwiftData + CloudKit 双模式构建
- **决策**：`CloudSyncService.makeModelContainer()` 根据用户偏好动态构建本地或云模式的 `ModelContainer`，**切换需重启 App**。
- **理由**：SwiftData 不支持运行时切换 `cloudKitDatabase` 选项，是硬限制。
- **影响**：UI 文案明确告知"重启生效"；不要试图实现热切换。

### 2. Attachment 双写：本地文件 + imageData
- **决策**：保存图片时同时写到 `Documents/Attachments/<uuid>.jpg` 并填充 `Attachment.imageData`（externalStorage）。
- **理由**：本地路径让 ImageRenderer / PDF / Widget 等"非 SwiftData"的代码无变动；imageData 走 CloudKit Asset 实现跨设备。
- **代价**：图片在设备上占双倍空间。可接受 —— 上限是用户主动开「同步图片附件」时才双写。
- **`AttachmentStore.loadData`** 是统一读图入口，自带降级回写逻辑。

### 3. 视频不上云
- **决策**：`CloudSyncService.includeMedia = true` 时仅图片填 imageData，视频留空。
- **理由**：CloudKit Asset 大文件上传慢，30s 视频可能 30MB+，体验差。
- **未来**：若做视频同步，建议走 `CKAsset` 直接上传 + 缩略图占位的 lazy 加载。

### 4. Widget 用快照而非直读 SwiftData
- **决策**：主 App 写入时调 `WidgetSnapshotPublisher.publish` → JSON 写到 App Group UserDefaults → Widget 读快照。
- **理由**：Widget Extension 直接打开 SwiftData ModelContainer 重启时易出错；快照模式简单可控。
- **代价**：要保证主 App 的写入路径都触发 publish（保存/删除两个点已覆盖）。

### 5. 微信 SDK 条件编译
- **决策**：`#if canImport(WechatOpenSDK)` 包裹所有 SDK 调用，未引入时自动降级到 `UIActivityViewController` 系统分享面板。
- **理由**：开发期不必接微信，CI/Windows 端能编译；上线前按 `docs/wechat-integration.md` 接入。
- **不要**直接 `import WechatOpenSDK` 到现有文件，会破坏条件编译。

### 6. 默认本地 + 显式同意流
- **决策**：CloudSyncSettingsView 首次开启同步时，**强制弹 sheet 显示完整条款，必须滑到底部「我已阅读并同意」按钮才启用**。
- **理由**：init.txt 8.1 隐私应对策略 + Apple 审核合规。
- **不要**为了方便去掉这一步。

### 7. 单点 AppRouter
- **决策**：通知 / Widget 深链 / 微信回调三路输入收敛到 `AppRouter` 的 `requestedTab` / `pendingMemoryID` / `requestQuickRecordFocus` 三个属性。
- **理由**：避免视图层各自处理深链导致状态不一致。
- **扩展**：新增外部入口时，往 AppRouter 加属性 + 在 RootView/对应 View 处理 onChange。

### 8. 纯函数模块独立可测
- **决策**：搜索 / 那年今日 / 时间分组 / 地点聚类做成 enum 静态方法，输入输出纯净。
- **理由**：可写真实测试，不依赖 UI 或 SwiftData 上下文（虽测试里仍用 in-memory ModelContainer 造数据，但函数本身无依赖）。
- **未来**：新增"猜你的情绪倾向"等分析能力，建议同样做成纯函数模块。

---

## 已知遗留与技术债

按严重度排序，每条带"为什么没做"和"做的话怎么做"。

### 🔴 上线必修

#### 1. SwiftData 真实 SchemaMigrationPlan
**为什么没做**：当前用户数 0，未上线，重装即可。
**上线必做**：定义 `VersionedSchema` v1（Attachment Codable struct）→ v2（Attachment @Model class），写迁移闭包把旧 JSON blob 拆成新表行。
**入手点**：参考 `https://developer.apple.com/documentation/swiftdata/preserving-your-app-s-model-data-across-launches` 第二节 "Make a versioned schema"。

#### 2. 微信 AppID + Universal Link
**为什么没做**：开放平台账号是产品/运营资产，不在工程师范围。
**上线必做**：替换 `project.yml` 中三处 `wxYOUR_WECHAT_APP_ID` 占位 + 配置 Universal Link 域名（`docs/wechat-integration.md` 有完整步骤）。

#### 3. CloudKit Schema 部署到 Production
**为什么没做**：第一次上线前才做。
**上线必做**：在真机跑过一次开启同步流程后，去 CloudKit Dashboard → Schema → **Deploy to Production**。否则 App Store 版用户的 iCloud 同步不会生效。

### 🟡 质量提升

#### 4. PDF / Markdown 导出搬到后台线程
**现状**：`runExport` 全 main thread 跑，~1000 条记忆需 1-3 秒。
**为什么没做**：SwiftData @Model 类不是 Sendable，跨 actor 警告多；当前规模可接受。
**改法**：用 `ModelActor` 在后台 actor 上执行 fetch + 渲染。

#### 5. ContactsService 同步遍历主线程
**现状**：`fetchAll()` 用 `enumerateContacts` 同步遍历，联系人 1000+ 时会卡 UI。
**改法**：包一层 `Task.detached`。

#### 6. KraftCard 噪点 Random 不可重现
**现状**：`Double.random(in:)` 每次重渲染纹理位置都变；用户感知到"卡片在抖"。
**改法**：用 SeededRandom（自己 implement Mersenne Twister 之类）或预生成纹理 PNG。

#### 7. 行尾 CRLF 警告刷屏
**现状**：Windows 端 commit 触发持续警告。
**改法**：仓库提交 `.gitattributes` 强制 LF（`* text=auto eol=lf`）。

### 🟢 锦上添花

| 项 | 说明 |
|---|---|
| 多语言 .strings | 当前全中文硬编码，准备出海需切资源文件 |
| Pro 模板真实实现 | 现有 4 个 case 占位，要做先确定订阅模式 |
| 高德地图 SDK | 国内 POI 精度比 Apple 自带 CLGeocoder 高 |
| 视频缩略图 | Attachment.thumbnailPath 字段已留，未利用 |
| 后端 BaaS | 微信登录拿到 code 后没有后端换 access_token，无法做用户体系 |
| 数据加密 | iOS 系统级加密已够用；如要端到端加密需引入 CryptoKit |
| 单元测试覆盖率 | 当前覆盖纯函数；UI 层 / Service 层未覆盖。考虑加 XCUITest |

---

## 上线前 Checklist

按时间轴排：

### 1. 提交 App Store 前 1 周
- [ ] 替换微信 AppID + Universal Link
- [ ] CloudKit Container 开发账号下创建 + Promote Schema
- [ ] App Group / iCloud / Associated Domains 三个 Capability 在 Apple Developer 后台勾选
- [ ] App Icon 真实素材替换（design/AppIcon.svg 是占位草稿）
- [ ] 写真实 SchemaMigrationPlan
- [ ] 在真机跑一遍 RUN.md 第 7 节的 13 项验证 checklist
- [ ] 隐私协议中"开发者所在地"等占位填充

### 2. 提交时
- [ ] 隐私问卷答案见 RUN.md 第 8 节"填提审材料"
- [ ] 截图素材：建议每 Tab 各 1-2 张，深色模式优先（Apple 偏好）
- [ ] App Store 描述：可直接挪用 `LegalDocuments.acknowledgements` 中"灵感来源"的口吻

### 3. 上线后 1 个月
- [ ] 监控 CloudKit Dashboard 的错误率
- [ ] 收集 GitHub Issues 中常见问题，扩充 `HelpCenterView`
- [ ] 决定 Pro 订阅商业化方案（参考 init.txt 第 7 节）

---

## 迭代路线图建议

### v0.2 — 打磨期（2-4 周）
- 视频缩略图生成与预览
- 高德地图 SDK 接入（国内 POI 精度）
- 后端 BaaS 雏形（微信登录用户体系）
- 数据导出加 JSON 选项（让其它工具二次加工）

### v0.3 — 出海准备（1 月）
- 多语言（英 / 日）
- 适配 iPad（当前 `TARGETED_DEVICE_FAMILY: "1"` iPhone Only）
- 适配横屏 / 大字号

### v0.4 — Pro 商业化（1 月，需产品决策）
- 4 个 Pro 模板真实实现
- StoreKit 订阅链路
- Pro 用户专属：高级模板 / 无限附件 / 云同步加速 / 时光书装订成 PDF / 深色主题切换
- 订阅价格策略：参考 init.txt 第 7 节 "12 元/月 或 98 元/年"

### v1.0 — 正式发版
- 完整端到端加密
- 视频跨设备同步
- Apple Watch 端（一键记录灵感）
- iCloud Family 共享相册式协作

---

## 术语表

| 术语 | 定义 |
|---|---|
| 时空锚点 | `SpacetimeAnchor` — 一条记忆自动捕获的时间 + 位置 + 天气 + 情绪四元组 |
| 那年今日 | `OnThisDayMatcher` — 找出过去同月同日的记忆，每天定时推送 |
| 双写策略 | Attachment 同时存本地文件路径 + SwiftData externalStorage 二进制 |
| 快照 | `WidgetSnapshot` — 主 App 推给 Widget 的轻量数据，跨进程通过 App Group |
| 引导版本 | `OnboardingService.currentVersion` — 改大此值让所有用户重看引导 |
| Pro 模板 | 当前未实现，4 个 ShareCardTemplate case 占位（杂志/胶片/水墨/霓虹） |
| 帮助中心 | `HelpCenterView` — 6 类 20 条 in-app FAQ，可搜索可深链系统设置 |
| 时光书 | PDF 导出的 A4 排版按月分章文档 |

---

## 致后续接手者

这份仓库的设计目标是让你**能在 5 分钟内 build 通**、**在 1 小时内理解整体架构**、**在 1 天内上手做改动**。

如果哪里没达到这个目标，请：
1. 改 `RUN.md` 或 `docs/build-errors.md` 让别人不踩同样的坑
2. 改 `CLAUDE.md` 让 AI 协作工具有更准的上下文
3. 改这份 `HANDOFF.md` 让下下一个接手者更顺利

仓库每次有破坏性变更，记得回到这个清单里更新对应章节。

— 拾忆开发团队 · 0.1.0
