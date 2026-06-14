# 版本管理

> 拾忆的版本号集中在 `project.yml` 一个地方维护，所有展示位运行时读取，避免散落。

---

## 版本号规则

遵循 [Semantic Versioning](https://semver.org/) 简化版：

| 字段 | 含义 | 例 |
|---|---|---|
| Major | 重大改版 / 不兼容变更 | `1.0.0` |
| Minor | 新功能 / 向后兼容 | `0.2.0` |
| Patch | bug 修复 / 微调 | `0.1.1` |
| Build | 提交到 TestFlight / App Store 的构建号，每次都需要递增 | `(42)` |

显示格式：`0.1.0 (1)` —— 营销版本 + 构建号。

---

## 改版本号的两种方式

### 方式 A：用脚本（推荐）

```bash
bash tools/bump-version.sh patch    # 0.1.0 → 0.1.1
bash tools/bump-version.sh minor    # 0.1.0 → 0.2.0
bash tools/bump-version.sh major    # 0.1.0 → 1.0.0
bash tools/bump-version.sh build    # 仅构建号 +1（同营销版本下迭代）
```

或者在 VS Code 里 `Ctrl+Shift+P → Tasks: Run Task → 🆙 Bump 版本号 (...)`。

每次执行：
1. 改 `project.yml` 中的 `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`
2. 提示下一步操作

### 方式 B：手动改

编辑 `project.yml` 顶部 `settings.base` 段：

```yaml
settings:
  base:
    MARKETING_VERSION: "0.1.0"
    CURRENT_PROJECT_VERSION: "1"
```

---

## 版本号在哪里被使用

```
project.yml
   ↓ XcodeGen
Info.plist
  CFBundleShortVersionString = $(MARKETING_VERSION)
  CFBundleVersion           = $(CURRENT_PROJECT_VERSION)
   ↓ 运行时
AppInfo.swift
  AppInfo.marketingVersion   ← Bundle.main.infoDictionary 取
  AppInfo.buildNumber
  AppInfo.fullVersion        ← 拼接
   ↓ UI
ProfileView   "版本 0.1.0 (1)"
AboutView     "版本 / 构建号" 行
```

**任何想显示版本的地方，都从 `AppInfo` 取，不要硬编码。** verify.sh 会检查这一点。

---

## 何时该 bump？

| 场景 | 选什么 |
|---|---|
| 提交到 TestFlight 测试 | `build`（同 0.1.0 下不断 +1） |
| 修了 bug，准备发新版 | `patch` |
| 加了新功能（如新模板） | `minor` |
| 重大改版（订阅商业化） | `major` |

**每次提交到 App Store / TestFlight，构建号必须比之前的全部记录都大** —— Apple 不允许同号回退。

`bump build` 在所有 bump 模式中**都会自动执行**，所以一次 `patch` 既改营销版本又自增 build。

---

## 历史版本变更记录

> 上线发版后，建议在这里追加每个版本的 changelog。

### 0.1.0 (1) - 2026-06-14
- 首次发布
- Phase 1/2/3 全部功能交付（详见 `HANDOFF.md`）

---

## CI / 提审注意

- App Store Connect 的"构建号"读 `CFBundleVersion` —— 即 `CURRENT_PROJECT_VERSION`
- TestFlight 看到的 "1.0.0 (5)" 是 `(MARKETING) (BUILD)`
- 上传前确保已 `bump-version.sh build` 至少一次
- 如果忘了，xcodebuild archive 会上传成功但 App Store Connect 会拒（提示构建号已存在）
