# 在 VS Code 中验证项目

> 本文档说明：在 Windows + VS Code 环境下，**不依赖 Mac / Xcode** 能做哪些验证。
> Mac 端的真机验证另见 `RUN.md` 第 7 节。

---

## 推荐 VS Code 扩展

仓库已通过 `.vscode/extensions.json` 推荐。打开仓库时 VS Code 会提示安装：

| 扩展 | 用途 |
|---|---|
| `sswg.swift-lang` | Swift 官方语言支持（语法高亮 / 跳转 / 错误提示） |
| `vknabel.vscode-apple-swift-format` | swift-format 风格 |
| `vadimcn.vscode-lldb` | 调试支持（Mac 端用） |
| `yzhang.markdown-all-in-one` | Markdown 编辑增强 |
| `eamodio.gitlens` | Git blame / 历史 |
| `streetsidesoftware.code-spell-checker` | 拼写检查 |

---

## 一键验证（最常用）

按 `Ctrl+Shift+B`（Mac: `Cmd+Shift+B`），选择「🔍 校验仓库一致性 (verify.sh)」，会自动跑：

1. ✅ `project.yml` YAML 合法性
2. ✅ Asset Catalog 所有 `Contents.json` 合法
3. ✅ `design/*.svg` XML 格式合法（需 `xmllint`）
4. ✅ `tools/*.sh` shellcheck 通过（需 `shellcheck`）
5. ✅ `AppInfo.author` 包含 `zizhi`
6. ✅ `ProfileView` 用 `AppInfo.fullVersion`，没有硬编码版本号
7. ✅ `project.yml` 用 `$(MARKETING_VERSION)` 变量

**没装的工具会友好跳过**而不是判失败。最低要求：bash + 一个能用的 python。

---

## 可选依赖

让校验更严格：

```bash
# Windows Git Bash 中可装 pyyaml（推荐）
pip install pyyaml

# macOS / Linux
brew install libxml2 shellcheck    # xmllint + shellcheck
```

---

## VS Code Tasks 列表

`.vscode/tasks.json` 提供这些任务（`Ctrl+Shift+P → Tasks: Run Task`）：

| 任务 | 作用 |
|---|---|
| 🔍 校验仓库一致性 | 跑 `verify.sh` |
| 📊 提交统计 | 看当前提交数 / 文件数 / 测试用例数 |
| 🆙 Bump 版本号 (patch) | `0.1.0` → `0.1.1` |
| 🆙 Bump 版本号 (minor) | `0.1.0` → `0.2.0` |
| 🆙 Bump 版本号 (build only) | 仅构建号 +1 |

---

## 静态检查清单

### 在 VS Code 里能看的

打开任意 `.swift` 文件后，sswft-lang 会做：

- 语法高亮
- 类型补全（部分场景，Mac 端 SourceKit-LSP 更全）
- 跳转到定义 (`F12`)
- 重命名 (`F2`)

⚠️ Windows 端 SourceKit 服务不全，**真正的类型检查仍要 Mac 端 `xcodebuild build`**。

### 不能看的

- iOS 17 API 是否真的存在（依赖 SDK）
- Preview 渲染
- 模拟器运行
- 单元测试结果

这些**必须**在 Mac 端跑 `xcodebuild test`，详见 `RUN.md` 第 7.5 节。

---

## 改了代码该跑什么

| 改了什么 | 必须跑 | 推荐跑 |
|---|---|---|
| 任何 .swift | — | `verify.sh` |
| `project.yml` | `verify.sh` 的 YAML 校验 | Mac 端 `xcodegen generate` |
| `Assets.xcassets/` | `verify.sh` 的 JSON 校验 | Mac 端 build |
| `tools/*.sh` | `verify.sh` 的 shellcheck | 真实运行一次 |
| 版本号 | bump-version.sh | git diff project.yml 确认 |

---

## CI 兜底

GitHub Actions（`.github/workflows/ci.yml`）会在 PR / push 时跑：

- Ubuntu lint job（与 verify.sh 重叠的部分）
- macOS build/test job（VS Code 完全做不了的部分）

VS Code 端 verify.sh 通过 ≠ CI 一定通过；但 verify.sh 失败 ≈ CI 必失败。
推送前先本地跑一次 verify.sh，能省一次 CI 来回。
