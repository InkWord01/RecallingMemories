# App Icon 设计说明

> 拾忆图标的设计意图、规范与改图流程。
> 矢量源在 `design/AppIcon.svg`，PNG/PDF 由 `tools/generate-icons.sh` 在 macOS 端生成。

---

## 设计语义

```
┌─────────────────────────────┐
│           ✦  ← 主星「此刻」    │
│              （捕捉的瞬间）    │
│       ✦                     │
│           ◌  ← 副星「那年今日」 │
│              （回响的回忆）    │
│                             │
│  渐变背景 = 一日时光的流动     │
│  暖桃 → 玫瑰粉 → 深紫         │
└─────────────────────────────┘
```

两颗星呼应产品的双时空概念：
- **主星** 居中偏上 —— 现在正在被记录的瞬间
- **副星** 错落右上 —— 「那年今日」会浮现的过去
- **渐变背景** —— 早晨的暖桃到深夜的紫，既是一日的光线流转，也是"记忆从清晰渐入沉淀"的隐喻

---

## 颜色

| 位置 | 色值 | 与系统色板的关系 |
|---|---|---|
| 顶部 | `#FFC4DC` | 与 AccentColor `#FFA0D8` 同系（亮一档） |
| 中段 | `#E89BC0 → #7A4F9C` | 玫瑰粉过渡到深紫 |
| 底部 | `#3A2868` | 与 LaunchBackground 一致 |
| 主星 | `#FFFFFF → #F8E5F0` 微渐变 | 给图形一点光泽 |
| 副星 | `#FFFFFF` 78% 不透明 | 暗示"过去的回响" |

**色板对齐原则**：图标顶部 ≈ AccentColor，图标底部 = LaunchBackground。
启动屏 → 引导页第一页 → 主界面 tint 色，三层视觉无缝。

---

## 视觉规范

| 项 | 值 | 原因 |
|---|---|---|
| 画布 | 1024×1024 | iOS 17+ AppIconSet 单尺寸通用 |
| 主星外径 | 280px | 占画布约 27%，足够醒目又不抢视觉 |
| 主星位置 | (512, 470) | y=46% 是光学中心（比几何中心略高） |
| 副星外径 | 110px | 主星 40%，构成 5:2 视觉重量比 |
| 副星位置 | (800, 268) | 黄金分割点附近，与主星形成对角张力 |
| 安全边距 | 主星离边 230px+ | iOS 圆角 mask 半径 ≈ 224px，留余量防被切 |

---

## 改图流程

### 1. 修改矢量源
直接改 `design/AppIcon.svg`，用任何 SVG 编辑器（Affinity Designer / Figma 导出 / 手写 path）。

### 2. 跨平台预览
在浏览器打开 `design/AppIcon.svg` 即可看效果（chrome / Safari / Firefox 都行）。
模拟 iOS 圆角：在浏览器开发者工具里给 svg 加 `border-radius: 22.5%`。

### 3. macOS 端导出
```bash
brew install librsvg     # 一次性
bash tools/generate-icons.sh
```
脚本会渲染 `AppIcon-1024.png` 到 `RecallingMemories/Resources/Assets.xcassets/AppIcon.appiconset/`。

### 4. 重新 build
```bash
xcodegen generate
xcodebuild build ...     # 或在 Xcode 里 ⌘B
```

---

## 不做清单

- ❌ 不放完整 App 名 "拾忆" 或 "RecallingMemories" 在图标上 —— Apple HIG 明示反对
- ❌ 不用照片底纹 / 实物质感 —— 与"极简、克制"理念冲突
- ❌ 不超过 3 个主要元素 —— 缩到 60×60 桌面尺寸要能辨识
- ❌ 不用纯黑 / 饱和度过高的色 —— 与系统其它图标排在一起会突兀

---

## 可能的迭代方向

| 方向 | 取舍 |
|---|---|
| 节日主题（中秋、春节） | iOS 16+ 支持替换图标，可做付费/限时主题 |
| 暗模式专属图标 | iOS 18+ 支持 dark/tinted variant，可做对应 SVG |
| Apple Watch 圆形适配 | 当前主体已居中，watchOS 渲染时圆形 mask 不会切到关键元素 |

---

## 当前 v0.1.0 的妥协

- 图标是开发者一笔一画写 SVG path 而不是设计师产出 —— 视觉精度有限
- 缺真机不同尺寸（小到 38×38）下的实测，无法验证最小可读性
- 上线前建议找设计师做一版专业图标，把 SVG 矢量替换掉即可，工程链路（`generate-icons.sh` / Asset Catalog）不变
