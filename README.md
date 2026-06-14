# 拾忆 (RecallingMemories)

[![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/ci.yml)

> 基于时空的灵感与记忆捕捉工具 — 一款极简、轻量的 iOS 端「当下」记录工具。

## 项目简介

通过快速绑定多媒体（照片、视频、人物）与时空环境（时间、地点），帮用户留住一瞬间的想法，并支持生成极具美感的图文卡片，无缝分享至微信。

详细产品文档见 [`init.txt`](./init.txt)。**Mac 端运行与发布步骤见 [`RUN.md`](./RUN.md)。**

## 技术栈

- **语言**：Swift 5.9+
- **UI 框架**：SwiftUI + UIKit（混编）
- **最低系统**：iOS 17.0+
- **持久化**：SwiftData
- **定位**：CoreLocation + 高德地图 SDK
- **地图**：MapKit
- **语音**：Speech Framework
- **后端**：Firebase / 腾讯云开发（BaaS）
- **第三方**：微信开放平台 SDK

## 项目结构

```
RecallingMemories/
├── App/                    # App 入口
├── Views/                  # SwiftUI 视图
│   ├── Record/             # 极速记录
│   ├── Timeline/           # 时间轴/瀑布流
│   ├── Map/                # 地图模式
│   └── Share/              # 分享卡片
├── Models/                 # 数据模型 (SwiftData)
├── Services/               # 服务层 (定位/存储/微信SDK)
├── Resources/              # 资源 (Assets/Info.plist)
└── Utils/                  # 工具类
```

## 开发环境

### Windows + VS Code (本仓库当前环境)

仅用于源码编辑与版本管理，**无法直接构建 iOS App**。

需安装：
- [VS Code](https://code.visualstudio.com/)
- VS Code 扩展：Swift (`sswg.swift-lang`)
- Swift Toolchain for Windows (可选，用于语法检查)

### macOS + Xcode (构建发布)

```bash
# 安装 XcodeGen (推荐，便于多人协作维护工程文件)
brew install xcodegen

# 生成 .xcodeproj
xcodegen generate

# 打开工程
open RecallingMemories.xcodeproj
```

## 里程碑

- **Phase 1 (4-6w)**：MVP 核心 — 文字/图片/时间/地点记录、微信登录与分享
- **Phase 2 (3-4w)**：视频、语音转文字、地图模式、桌面小组件
- **Phase 3 (4w)**：云端同步、Pro 订阅、「那年今日」推送

## License

私有项目，未授权前禁止分发。
