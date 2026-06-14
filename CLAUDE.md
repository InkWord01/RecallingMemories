# CLAUDE.md

> 本文件为 Claude Code / AI 编程助手提供项目上下文。

## 项目

**拾忆 (RecallingMemories)** — 基于时空的灵感与记忆捕捉工具，iOS 原生 App。

完整产品文档见 [`init.txt`](./init.txt)。

## 技术约束

- Swift 5.9+，SwiftUI + UIKit 混编
- 最低 iOS 17.0（依赖 SwiftData / 新 Map API / `onChange(of:_:)` 双值闭包等 iOS 17+ 能力）
- SwiftData 本地持久化（MVP 阶段不上云）
- 微信开放平台 SDK 用于登录与分享
- 高德地图 SDK 用于国内 POI（CoreLocation 补充）

## 开发环境

- **当前仓库主机**：Windows 10 + VS Code（仅源码编辑，无法构建 iOS）
- **构建环境**：macOS + Xcode 15+，使用 XcodeGen 生成 .xcodeproj（见 `project.yml`）

## 目录约定

```
RecallingMemories/
├── App/         # @main 入口
├── Views/       # SwiftUI 视图（按业务模块分子目录）
├── Models/      # @Model 数据层
├── Services/    # 单例服务（定位、微信、渲染等）
├── Resources/   # Assets / Info.plist
└── Utils/       # 通用工具
```

## 命名与代码风格

- 文件首部使用中文注释说明该文件职责。
- 视图用 `XxxView`、视图模型用 `XxxViewModel`、服务用 `XxxService`。
- 注释优先中文，标识符英文。
- 缩进 4 空格；行宽建议 ≤ 120。

## 当前进度

Phase 1 MVP 骨架已搭建（2026-06-14）：
- ✅ 项目结构
- ✅ 数据模型 (`Memory`, `Person`, `Attachment`)
- ✅ Tab 主框架（记录/时光/足迹/我的）
- ✅ 极速记录页 + ViewModel 骨架
- ✅ 时间轴 / 地图 / 个人中心 占位
- ✅ 定位服务、微信服务、分享卡片渲染器骨架
- ⏳ TODO：接入相册/相机选择器、Speech 语音转文字、微信 SDK、SwiftData 写入逻辑、地图 POI 详情卡片

## 注意事项

- **不要**在 `Resources/` 之外提交 `Info.plist`（由 XcodeGen 生成）。
- 隐私敏感字段（`NSLocation*UsageDescription` 等）已在 `project.yml` 中配置。
- 微信 AppID 占位 `wxYOUR_WECHAT_APP_ID`，正式集成时需替换并配置 Universal Link。
