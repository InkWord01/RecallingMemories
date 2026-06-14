# 打包发版指南

> 当前 Windows 主机无法本地打 iOS 包（Apple 工具链锁死 macOS）。
> 这份文档说明用 **GitHub Actions 云端 macOS runner** 自动打包的完整流程。

---

## 一句话总结

推个 tag 到 GitHub，10 分钟后能在 Releases 页面下载到 unsigned `.ipa` 与模拟器版 `.app.zip`。

---

## 前置：把仓库推到 GitHub

如果还没建远端：

```bash
# 在 https://github.com/new 建一个仓库（命名建议 RecallingMemories，公开/私有都行）
# 然后回到本地：
cd D:/WorkAppCode/RecallingMemories
git remote add origin https://github.com/<你的用户名>/RecallingMemories.git
git branch -M main
git push -u origin main
```

私有仓库 GitHub Free 账号也能用 Actions（macOS runner 每月 2000 分钟免费额度，单次打包约 8-12 分钟）。

---

## 打包方式

### 方式 A：手动触发（开发期推荐）

1. 浏览器打开 `https://github.com/<用户名>/RecallingMemories/actions`
2. 左侧选 **Release iOS Build** workflow
3. 右上角 **Run workflow** → 可选填构建号 → **Run**
4. 等 8-12 分钟，跑完后 Artifacts 区会出现 `RecallingMemories-0.1.0-1`，下载即可

### 方式 B：推 tag 自动发版（正式版）

```bash
# 先 bump 版本号（可选）
bash tools/bump-version.sh patch    # 0.1.0 → 0.1.1

# 提交版本变更
git add project.yml
git commit -m "chore: bump 版本到 0.1.1 (2)"

# 打 tag 并推送
git tag v0.1.1
git push origin main
git push origin v0.1.1               # 触发 release workflow
```

跑完后会**自动创建 GitHub Release**，包含三个文件：

| 文件 | 用途 |
|---|---|
| `*-unsigned.ipa` | 未签名 ipa，用 [Sideloadly](https://sideloadly.io) / [AltStore](https://altstore.io) 自签后装真机 |
| `*-simulator.app.zip` | 解压后拖到 Xcode 模拟器即可运行（用于产品演示） |
| `*.app.zip` | 真机版 .app（未签名），用真实证书重签后可分发 |

---

## 装到设备的方法

### 模拟器（最简单，只需 macOS）

```bash
unzip RecallingMemories-0.1.1-2-simulator.app.zip
xcrun simctl install booted RecallingMemories.app
```

或在 Xcode 启动模拟器后，把 `.app` 直接拖进模拟器窗口。

### 真机 — Sideloadly 自签（无 Apple Developer 账号也行）

1. 下载 [Sideloadly](https://sideloadly.io)（macOS / Windows 都有）
2. 用数据线连 iPhone，运行 Sideloadly
3. 把下载的 `*-unsigned.ipa` 拖进去
4. 输入 Apple ID（普通免费账号即可）→ 等几分钟
5. iPhone 设置 → VPN 与设备管理 → 信任开发者
6. 主屏出现拾忆图标，可正常运行

⚠️ 免费账号自签的 App **每 7 天过期**，到期后需要重签。

### 真机 — TestFlight（最终发版方案）

需要：
- Apple Developer 付费账号（$99/年）
- App Store Connect 创建对应 App
- 配置签名证书 + Provisioning Profile

详细见 `RUN.md` 第 8 节。

---

## 当前 release.yml 的限制

打的是 **unsigned** 包，原因：
1. CI 没有真实 Apple Developer 证书
2. 加证书就要 secrets，泄露风险

如果要让 CI 直接出能 TestFlight 的签名包，需要追加：

| 配置 | 在哪里设 |
|---|---|
| `APP_STORE_CONNECT_API_KEY` | GitHub 仓库 Settings → Secrets and variables → Actions |
| `APP_STORE_CONNECT_API_KEY_ID` | 同上 |
| `APP_STORE_CONNECT_ISSUER_ID` | 同上 |
| `BUILD_CERTIFICATE_BASE64` | 把 .p12 证书 base64 后存 |
| `P12_PASSWORD` | 同上 |
| `PROVISIONING_PROFILE_BASE64` | 把 .mobileprovision base64 后存 |

完整签名 + 上传 TestFlight 的 workflow 是另一份模板，等真实证书就绪后再加。

---

## 常见问题

| 现象 | 原因 / 修法 |
|---|---|
| Workflow 跑到 "Build .app" 步骤失败 | 99% 是 Swift 编译错误。点失败的 step 看完整日志，按错误信息改代码 |
| `xcodegen: command not found` | release.yml 里 brew install 失败了，重试一次 |
| Artifacts 下载下来 .ipa 是 0 字节 | "Package .ipa" 步骤里 .app 路径错了，看 step 输出的 `find` 列表 |
| Sideloadly 自签后启动闪退 | 可能 entitlements 不被免费账号支持（如 iCloud / App Group），临时把 entitlements 文件清空打一次包验证 |
| 60 分钟超时 | 提升 timeout-minutes，或者 `concurrency: cancel-in-progress: true` 避免堆积 |

---

## release.yml 自身的演化

未来可能加的能力：
- 上传到 TestFlight（需证书）
- 自动写 Changelog（从 git log 提取）
- 通知钉钉/飞书构建结果
- 多目标并发（debug / release / 不同环境）

当前先解决"能从 Windows 出包"这个核心诉求。
