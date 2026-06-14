# 微信 SDK 集成指南（macOS 端）

> 当前仓库的 `WeChatService.swift` 用 `#if canImport(WechatOpenSDK)` 做了条件编译。
> Windows 端无 SDK 也可正常通过编译；下面是把它真正接通的步骤。

## 1. 微信开放平台

1. 打开 https://open.weixin.qq.com → 登录开发者账号
2. **创建移动应用** → iOS 平台
   - Bundle ID 填：`com.recallingmemories.app`
   - 拿到 **AppID**（形如 `wx1234567890abcdef`）
3. 等待审核通过

## 2. 配置 Universal Link

1. Apple Developer 后台为 Bundle ID 开启 **Associated Domains** 能力
2. 准备一个 HTTPS 域名，托管 `apple-app-site-association` 文件，路径如：
   ```json
   {
     "applinks": {
       "apps": [],
       "details": [{
         "appID": "TEAMID.com.recallingmemories.app",
         "paths": ["/wechat/*"]
       }]
     }
   }
   ```
3. 验证：浏览器访问 `https://your.domain/.well-known/apple-app-site-association`，确认能拿到 JSON
4. 在微信开放平台后台填入 Universal Link：`https://your.domain/wechat/`

## 3. 引入 SDK

**SPM（推荐）**：
```
File → Add Packages → 输入：
https://github.com/Tencent/WeChatOpenSDK-Swift
```

**CocoaPods**：
```ruby
pod 'WechatOpenSDK_XCFramework'
```

## 4. 替换占位

打开 `project.yml`，替换：

```yaml
WeChatAppID: wxYOUR_WECHAT_APP_ID         → 你的真实 AppID
WeChatUniversalLink: https://your.universal.link/wechat/  → 真实 Universal Link
```

`CFBundleURLTypes` 段：

```yaml
- CFBundleURLName: wechat
  CFBundleURLSchemes:
    - wxYOUR_WECHAT_APP_ID                → 同样替换
```

执行：
```bash
xcodegen generate
```

## 5. Capabilities

在 Xcode 项目 → RecallingMemories target → Signing & Capabilities：

- ✅ Associated Domains：添加 `applinks:your.domain`
- ✅ App Groups：`group.com.recallingmemories.app`（已生成）

## 6. 验证

1. 在真机上安装 App（模拟器没法调起微信）
2. 「我的」→「微信登录」 → 弹出微信 → 授权 → 自动回到 App，列表项显示 code
3. 任意记忆 → 分享 → 「好友 / 朋友圈 / 收藏」三个绿色按钮直接送达微信

## 常见问题

| 现象 | 排查 |
|---|---|
| 点击微信登录无反应 | `isWXAppInstalled()` 返回 false → 检查 `LSApplicationQueriesSchemes` 是否有 `weixin` |
| 唤起微信但回不来 | Universal Link 未生效 → 浏览器测域名 JSON / 重启设备 / 重新 sideload |
| 分享按钮点了静默失败 | 缩略图 > 32KB 被微信丢弃 → `WeChatService.thumbnail` 已自动压缩，自检日志 |
| 收到回调但 errCode = -2 | 用户取消，正常流程 |

## 不集成微信 SDK 的降级

如果暂时不接：

- 「微信登录」按钮会抛 `WeChatError.sdkUnavailable`
- 分享面板里**不会出现**绿色微信直发按钮（`isWeChatInstalled` 为 false）
- 用户仍可走「保存到相册 → 在微信里发图」或「更多」（系统 `UIActivityViewController`）
