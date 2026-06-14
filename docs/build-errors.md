# 首次构建预计错误清单

> 这份文档是**Windows 端开发 → Mac 端首次构建**时可预见报错的合集。
> 每条都给出「现象 → 根因 → 修法」三段式，方便照着排查。
>
> 与 `RUN.md` 第 9 节「常见坑」的区别：那里是日常使用问题，这里是**首次跑通**前的硬骨头。

---

## 🔴 P0 阻塞类（不修就编译/启动失败）

### E1. `xcodegen: command not found`
**现象** 执行 `xcodegen generate` 报命令找不到。
**根因** Mac 上没装 XcodeGen。
**修** ```brew install xcodegen```

---

### E2. `rsvg-convert: command not found`
**现象** 跑 `tools/generate-icons.sh` 报错。
**根因** 没装 librsvg。脚本会自动降级到 `qlmanage`，但精度差很多。
**修** ```brew install librsvg```

---

### E3. AppIcon.appiconset 缺失 PNG → 编译失败
**现象**
```
error: An app icon set named "AppIcon" could not be found.
```
**根因** Asset Catalog 里有 `Contents.json` 但 PNG 是 .gitignore 排除的。
**修** 必须先跑 `bash tools/generate-icons.sh` 再 `xcodegen generate`。

---

### E4. `Provisioning profile … doesn't include the iCloud Container`
**现象** Build 阶段报 entitlements 不匹配。
**根因** Apple Developer 后台 Bundle ID 没有勾上 iCloud / App Groups。
**修**
1. https://developer.apple.com/account → Identifiers → 你的 App ID → Edit
2. 勾上 **iCloud** + **App Groups**，点 Configure
3. 创建/选择 Container：`iCloud.com.recallingmemories.app`
4. 创建/选择 Group：`group.com.recallingmemories.app`
5. Xcode 中 Signing & Capabilities → 触发自动重新 provision

---

### E5. Widget Extension Bundle ID 前缀不匹配
**现象**
```
Embedded binary's bundle identifier is not prefixed with the parent app's bundle identifier.
```
**根因** Widget 的 bundle ID（`com.recallingmemories.app.widget`）必须以主 App ID（`com.recallingmemories.app`）为前缀。
**修** 检查 `project.yml` 中两个 target 的 `PRODUCT_BUNDLE_IDENTIFIER` 一致性，重新 `xcodegen`。

---

### E6. `Cannot find type 'WXApi' in scope`
**现象** 编译 `WeChatService.swift` 报错。
**根因** 你**主动尝试**集成微信 SDK 但还没引入 SPM 包。
**修** 两选一：
- ✅ **不接微信**：什么都不做，`#if canImport(WechatOpenSDK)` 会让代码自动跳过
- ✅ **接微信**：见 `docs/wechat-integration.md`，引入 SPM 后即可

> 注意：**Xcode 偶尔在 SPM 引入后仍报此错** —— Product → Clean Build Folder 后重 build。

---

### E7. SwiftData Schema 迁移失败
**现象**
```
SwiftData/SchemaCompatibility.swift:N: Fatal error: Schema migration failed
```
**根因** 仓库期间改过 `Memory` / `Person` 字段（移除 `@Attribute(.unique)`、加 `inverse`），如果你**重装在已有数据库的设备**会触发迁移失败。
**修**（开发期最快）
- 真机：长按拾忆图标 → 删除 App
- 模拟器：Device → Erase All Content and Settings
- 生产期需要做 `VersionedSchema` + `SchemaMigrationPlan`，目前未上线，留给真要发版前补

---

## 🟡 P1 非阻塞类（能跑但行为不对）

### E8. 真机首次启动黑屏 1 秒
**现象** 启动屏一闪过后画面黑。
**根因** `LaunchBackground` 颜色集 P3 渲染 + 系统第一帧未上色。
**修** 实际是预期行为，已在 `UILaunchScreen.UIImageRespectsSafeAreaInsets: true` 中尽量缓解。冷启动后不会再出现。

---

### E9. Widget 装上是空的
**现象** 主屏添加 Widget 后显示假数据「下午阳光很好…」。
**根因** Widget 通过 App Group 共享 UserDefaults 读快照；主 App 还没运行过任何写入。
**修**
1. 主 App 至少保存一条记忆（触发 `WidgetSnapshotPublisher.publish`）
2. 或者主屏 → 编辑 Widget → 重新选择，强制刷一次 timeline

---

### E10. 通讯录 / 麦克风 / 位置 / 通知 任一权限弹窗不出
**现象** 点对应按钮无反应。
**根因** Info.plist 缺对应 `NS*UsageDescription`。本仓库已配齐，但若 `xcodegen generate` 失败可能没注入。
**修**
- 检查 `Build Settings → Info.plist Path` 是否指向 `RecallingMemories/Resources/Info.plist`
- 模拟器：Settings → Privacy & Security → 重置位置/通讯录权限
- 真机：删除 App 重装

---

### E11. CloudKit 同步开启后没有同步
**现象** 我的 → 云同步 开启 → 重启 App → 数据没出现在另一台设备。
**根因** 多种可能：
1. 两台设备 iCloud 账号不同
2. 设备没联网或 iCloud 储存满
3. CloudKit Dashboard 的 schema 还没 Promote 到 Production
**修**
1. 设置 → Apple ID → 确认两台设备同账号 + iCloud Drive 已启用
2. https://icloud.developer.apple.com → 你的 Container → Schema → **Deploy to Production**（首次必做）
3. 看 Console.app 过滤 `CloudKit` 关键字，定位具体错误

---

### E12. 微信回调进 App 后停在分享面板而非回到拾忆
**现象** 分享到微信后，从微信回切应用栈不是拾忆。
**根因** Universal Link 没生效，回退用的是 URL Scheme，行为有差异。
**修**
1. 浏览器访问 `https://your.universal.link/.well-known/apple-app-site-association` 必须 200 + 正确 JSON
2. 重启 iPhone（系统会重新拉取 association 文件，缓存约 12 小时）
3. 见 `docs/wechat-integration.md`

---

## 🟢 P2 友善提示类（不影响功能）

### W1. CRLF 行尾警告
**现象** Xcode 控制台或 git 反复刷
```
warning: in the working copy of '...', LF will be replaced by CRLF the next time Git touches it
```
**根因** Windows 端用 CRLF，Mac/iOS 编译器期望 LF。Xcode 能正确解析，不是错误。
**修**（可选）
```bash
git config core.autocrlf input
git rm --cached -r .
git reset --hard
```

---

### W2. SwiftData `Sendable` 警告
**现象** Build 警告刷屏
```
Capture of 'memory' with non-sendable type 'Memory' in a `@Sendable` closure
```
**根因** `@Model` 类不是 `Sendable`，跨 actor 传会警告。本仓库目前所有写入都在 `@MainActor`，警告可忽略。
**修** 真要消除：把 Memory 转成纯值类型 DTO 再跨边界。当前规模不需要。

---

### W3. Preview 偶发 crash
**现象** Xcode 右侧 SwiftUI Preview 红屏。
**根因** Preview 是独立进程，对 SwiftData ModelContainer 初始化敏感。
**修** Cmd+Option+P 重启 Preview；仍不行就 `~/Library/Developer/Xcode/DerivedData/` 删 derived data 重 build。

---

### W4. CI 第一次跑很慢
**现象** GitHub Actions Mac runner 跑 12+ 分钟。
**根因** `brew install xcodegen librsvg` 首次拉 bottle 慢；后续命中 actions cache 后 < 5 分钟。
**修** 等 / 给 brew 步骤加 `actions/cache@v4` 缓存（暂未做，量小不值得）。

---

### W5. xcpretty 缺失，xcodebuild 输出难读
**现象** CI 或本地命令行 build 输出像瀑布流。
**根因** xcpretty 没装。
**修** ```sudo gem install xcpretty```

---

## 一键自检清单（按顺序跑）

```bash
# 0. 进仓库
cd RecallingMemories

# 1. 装依赖（5-10 分钟）
brew install xcodegen librsvg
sudo gem install xcpretty

# 2. 生成图标
bash tools/generate-icons.sh

# 3. 生成工程
xcodegen generate

# 4. 命令行试 build
xcodebuild build \
  -project RecallingMemories.xcodeproj \
  -scheme RecallingMemories \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -configuration Debug \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  | xcpretty --color

# 5. 跑测试
xcodebuild test \
  -project RecallingMemories.xcodeproj \
  -scheme RecallingMemories \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  | xcpretty --color

# 6. 打开 Xcode 接着开发
open RecallingMemories.xcodeproj
```

如果 1-5 步都通过，说明仓库已成功移植到 Mac 端，剩下的问题就是日常迭代。

---

## 求助通道

- 上面 12 条 + 5 条都不匹配？打开 Xcode → Report Navigator (Cmd+9) → 选最近一次 build → 右上角导出 `.xcresult` 包
- 把这个包发给团队，包含完整编译/链接错误链，比手动复制日志更全
