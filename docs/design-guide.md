# 设计风格指南

> 本文档沉淀拾忆视觉语言规范，让任何工程师 / 设计师上手新页面时，
> 能在不破坏既有节奏的前提下做出"像拾忆"的界面。
>
> 适用范围：iOS 主 App、桌面小组件、分享卡片、PDF 导出。
>
> 最后更新：2026 年 6 月 14 日

---

## 0. 核心理念

> **极简、温柔、克制 —— 像深夜的一束侧光，不打扰你的思绪，但能照亮一隅记忆。**

三条铁律：

1. **内容优先于装饰** —— UI 退到内容后面，不与文字 / 照片争视觉中心
2. **深色优先** —— 灵感常在夜间，深色降低视觉干扰
3. **有生命的克制** —— 用呼吸 / 脉冲等微动效赋予 App 情感，但绝不喧宾夺主

---

## 1. 色彩

### 1.1 品牌色

| 用途 | 色值 (P3) | Hex | 使用场景 |
|---|---|---|---|
| **AccentColor** 主品牌 | `(R 1.000, G 0.627, B 0.847)` | `#FFA0D8` 暖粉 | 全局 tint：按钮、链接、选中态 |
| **LaunchBackground** 启动屏 | `(R 0.227, G 0.157, B 0.408)` | `#3A2868` 深紫 | 启动屏背景，过渡到引导第一页 |

> AppIcon 渐变背景从顶部 `#FFC4DC`（与 AccentColor 同系亮粉）流向底部 `#3A2868`（即 LaunchBackground）。
> 这样启动屏 → 引导页 → 主界面三层视觉无缝。

### 1.2 引导四色（与四页主题对应）

| 页 | 主题 | tint 色 | 备注 |
|---|---|---|---|
| 1 | 记下此刻 | `(1.0, 0.85, 0.55)` 暖橙 | 灵感与温度 |
| 2 | 时空都在 | `(0.55, 0.85, 1.0)` 浅蓝 | 空间与延展 |
| 3 | 那年今日 | `(1.0, 0.7, 0.85)` 粉红 | 情感与回忆 |
| 4 | 默认本地 | `(0.7, 0.95, 0.7)` 嫩绿 | 安心与隐私 |

### 1.3 系统色复用规则

**不要自定义灰阶 / 状态色。** 一律用系统语义色，自动适配深浅模式：

```swift
.foregroundStyle(.primary)     // 主文本
.foregroundStyle(.secondary)   // 次文本（时间、元信息）
.foregroundStyle(.tertiary)    // 辅助文本（计数、提示）
.foregroundStyle(.tint)        // 品牌强调（按钮、链接）
.foregroundStyle(.red)         // 录音 / 删除 / 警告
.foregroundStyle(.orange)      // 提醒 / 推荐合并 / Pro 锁
.foregroundStyle(.green)       // 微信品牌 / 成功状态
```

### 1.4 半透明叠加（深色卡片 / 输入框）

```swift
.background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))  // 时光卡片
.background(.white.opacity(0.06), in: Capsule())                           // 情绪 chip 默认态
.background(.white.opacity(0.20), in: Capsule())                           // 情绪 chip 选中态
.background(.ultraThinMaterial)                                            // 工具栏 / 分享面板
```

**为什么用 `.white.opacity()` 而非 fill 色？** 让背景渐变 / 主题色透出，与上下文呼应。

---

## 2. 字体

### 2.1 字号层级（Dynamic Type 友好）

```swift
.font(.largeTitle)    // 章节封面（PDF 月份大字）
.font(.title)         // 文档主标题
.font(.title2.bold()) // 法律文档章节标题
.font(.title3)        // 详情页正文
.font(.headline)      // 卡片主信息
.font(.body)          // 列表行 / 引导副标
.font(.subheadline)   // 元信息行 / 段落正文
.font(.caption)       // 时间 / 计数 / 标签
.font(.caption2)      // 角标 / 微小辅助
```

**铁律**：除分享卡片渲染 / PDF 导出外，**禁止用 `.font(.system(size: ...))` 写死字号**，否则破坏 Dynamic Type 适配。

### 2.2 字体设计

| 用途 | 设计 | 例子 |
|---|---|---|
| 主体 UI | `.default` 系统圆体（苹方 SC） | 列表 / 按钮 / 表单 |
| 时间 / 数字 / 标题 | `.serif` 衬线 | 引导大字、详情时间、卡片标题 |
| 等宽数字 | `.monospacedDigit()` 修饰符 | 计数对齐 |

**衬线字体的使用** 给"记忆"和"时间"赋予仪式感：

```swift
Text("此刻").font(.system(size: 28, weight: .bold, design: .serif))
Text("2025 年 6 月").font(.system(size: 80, weight: .bold, design: .serif))
```

### 2.3 字重

```swift
.weight(.light)     // 时间标签、装饰大字
.weight(.regular)   // 正文（默认）
.weight(.medium)    // 强调段落 / 选中态
.weight(.semibold)  // Section header / 引导标题
.weight(.bold)      // 文档标题、主按钮
```

**禁止用 `.weight(.heavy) / .black`** —— 与"克制"理念冲突。

---

## 3. 间距与排版

### 3.1 spacing 系统（4 的倍数）

| 数值 | 用途 |
|---|---|
| 4 | 图标内 padding |
| 6 | 紧凑 stack（行内 inline 标签） |
| 8 | 默认 stack 间距 |
| 12 | 卡片内元素间距 |
| 14 | 卡片内 padding |
| 16 | 列表行水平 padding / 工具条间距 |
| 20 | 详情页主 padding |
| 24 | Section 之间 |
| 32 | 引导大间距 |

**禁止 5 / 7 / 13 / 25 这种偏移**，整个仓库视觉节奏要保持 4px 网格。

### 3.2 圆角

| 形态 | 圆角 |
|---|---|
| 头像 / 图标按钮 | `Circle()` 完全圆 |
| 缩略图 | `RoundedRectangle(cornerRadius: 6-8)` |
| 卡片 | `RoundedRectangle(cornerRadius: 12-14)` |
| 模板预览 | `RoundedRectangle(cornerRadius: 24)` |
| 胶囊按钮 / chip | `Capsule()` |

### 3.3 行距

```swift
Text(memory.text).lineSpacing(3)   // 列表行 / 卡片行
Text(memory.text).lineSpacing(4)   // 详情页 / 段落
Text(memory.text).lineSpacing(12)  // 分享卡片大字
```

---

## 4. 组件库

### 4.1 EmptyStateView 空态卡

```
   ⭕ 大图标（tint 圆环 + 中心 SF Symbol）
   ─────
   标题（title3.bold）
   说明文字（subheadline.secondary）
   ─────
   [CTA 胶囊按钮 — 带方向感]
   提示文字（caption2.tertiary，可选）
```

**铁律**：每个空态都要给出**至少一条 CTA 或 hint**，不能让用户对着图标发呆。

### 4.2 列表卡片

```
[memo row]
┌────────────────────────────────────┐
│ 09:32  💡            ↗(swipe)      │
│ 文本主体（最多 6 行）                │
│ [缩略图网格]                         │
│ 📍 地点  ·  👥 人物                  │
└────────────────────────────────────┘
   padding: 14
   background: .white.opacity(0.04)
   cornerRadius: 14
```

### 4.3 chip / capsule

```swift
Text("💡顿悟")
    .font(.caption)
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(.white.opacity(0.06), in: Capsule())  // 默认
    .background(.white.opacity(0.20), in: Capsule())  // 选中

// Pro 锁标
ZStack(alignment: .topTrailing) {
    chip
    Image(systemName: "lock.fill")
        .padding(4)
        .background(Color.orange, in: Circle())
        .offset(x: 6, y: -6)
}
```

### 4.4 工具按钮

- 尺寸：`36×36`，与右侧"保存"胶囊高度对齐
- 字号：`.font(.title3)`
- 选中态：`.tint` 色（如人物按钮已选时）
- 录音中：红色 + phaseAnimator 脉冲

### 4.5 分享 / 导出卡片三模板

参考 `ShareCardRenderer.swift`：

| 模板 | 风格 | 主色 | 字体 |
|---|---|---|---|
| 极简 | 渐变深紫 | `(0.08, 0.08, 0.16) → (0.16, 0.10, 0.22)` | serif 大字 |
| 拍立得 | 米黄底 + 白边 | `(0.96, 0.94, 0.90)` | medium |
| 卡纸 | 复古牛皮纸 + 噪点 | `(0.92, 0.86, 0.74)` | serif 衬线 |

---

## 5. 动效

### 5.1 动效目录

| 场景 | 动效 | 时长 | API |
|---|---|---|---|
| 录音呼吸点 | 透明度 1.0 ↔ 0.4 | 0.7s | `phaseAnimator` |
| 录音脉冲圈 | 缩放 + 淡出 | 1.2s | `phaseAnimator` |
| 录音 / 停止图标切换 | symbolEffect.replace | 系统默认 | `.contentTransition(.symbolEffect(.replace))` |
| 保存按钮启用态 | 颜色过渡 | 0.2s | `.animation(.easeInOut)` |
| 引导页码点 | 胶囊宽度 6 ↔ 20 | spring response 0.3 | `.animation(.spring)` |
| Cluster Pin 选中 | 缩放 36 ↔ 44 | spring response 0.3 | `.animation(.spring)` |
| Toast 出现 | 上滑 + 淡入 | 系统默认 | `.transition(.move + .opacity)` |
| Help item 展开 | 淡入 + 上滑 | 0.2s | `withAnimation(.easeInOut)` |

### 5.2 动效铁律

1. **永远尊重 `accessibilityReduceMotion`**
   ```swift
   if viewModel.isRecording && !reduceMotion {  // ← 守卫
       Circle().phaseAnimator(...)
   }
   ```

2. **状态切换有过渡，纯装饰循环不要 repeatForever 不停转**

3. **动效服务于沟通，不服务于炫技** —— 每个动效都要回答"它告诉用户什么"
   - 呼吸点：录音正在工作
   - 脉冲圈：声音波动的隐喻
   - 页码点宽度：当前位置

4. **动效装饰元素一律 `accessibilityHidden(true)`** —— VoiceOver 不读

---

## 6. 图标与符号

### 6.1 SF Symbols 优先

整个仓库**禁止使用 emoji 当 UI 图标**（除情绪标签的"内容性"emoji 外）。理由：

- SF Symbols 自动适配 Dynamic Type / 重量 / 渲染模式
- 跨设备一致
- 矢量、可变色

### 6.2 常用图标对照表

| 业务概念 | 图标 |
|---|---|
| 记录 | `square.and.pencil` |
| 时光 | `list.bullet.rectangle` |
| 足迹 / 地图 | `map` |
| 我的 / 个人 | `person.circle` |
| 那年今日 | `calendar.badge.clock` |
| 通知 | `bell.badge` |
| 帮助 | `questionmark.bubble.fill` |
| 隐私 / 安全 | `hand.raised.fill` / `lock.shield.fill` |
| 致谢 | `heart.text.square` |
| 云同步 | `icloud` / `icloud.fill` |
| 数据导出 | `square.and.arrow.up.on.square` |
| 分享 | `square.and.arrow.up` |
| 搜索 | `magnifyingglass` |
| 添加照片 | `photo.on.rectangle` |
| 人物 | `person.2` / `person.2.fill` |
| 录音 / 麦克风 | `mic.fill` / `stop.circle.fill` |
| 位置 | `location.fill` |
| 灵感 | `sparkles` |
| Pro 锁 | `lock.fill`（橙色 Circle 角标） |

### 6.3 符号渲染模式

```swift
.symbolRenderingMode(.hierarchical)   // 单色多层级（引导大图标）
.symbolRenderingMode(.multicolor)     // 系统多色
.foregroundStyle(.white, .black.opacity(0.5))  // 双色 fill
```

### 6.4 情绪标签 emoji（内容性）

仅 5 个，固定不变，与 RecordViewModel.moodOptions 一致：

```swift
["💡顿悟", "🔥激动", "😌平静", "🌙怅然", "🌿温柔"]
```

新增情绪标签需团队评审，避免无序膨胀。

---

## 7. 文案

### 7.1 语气

- **第二人称**："你的记忆"、"和谁在一起"、"你曾在此时此地有过一个想法"
- **轻量、温柔**：不用"请"、"必须"、"严格"等命令式
- **避免技术术语**：不说"SwiftData / CloudKit / Schema"，说"记忆 / 同步 / 备份"
- **占位文案有性格**：
  - 输入框 placeholder：`"记录此刻的想法…"`（不是 `"请输入"`）
  - 录音中：`"聆听中…"`（不是 `"录音进行中"`）
  - 空态：`"还没有足迹 — 记录时给个定位，这里就会浮出旅程的地图"`

### 7.2 标点

- 中文用全角标点：`，。：；！？`
- 不在中文句末加英文句点
- 用「」而非 ""（中文引号）
- 省略号用 `…`（U+2026），不用 `...`
- 数字与中文之间留空格：`12 条记忆`、`3 年前的今天`

### 7.3 时间表达

| 场景 | 格式 |
|---|---|
| 列表行时间 | `09:32` |
| 详情页 | `2026 年 6 月 14 日 周日` |
| 导航标题（紧凑）| `6 月 14 日 · 09:32` |
| 时光分组 | `今天 / 昨天 / 本周 / 本月 / 6 月 / 2025 年 11 月` |
| 那年今日 | `1 年前 · 2025` / `3 年前 · 2023` |
| 通知正文 | `2 年前的今天，你写下：「…」` |

### 7.4 计数表达

```
3 条        ← 简短列表
共 12 条     ← 强调
3 年前的今天  ← 时间感
等 5 人      ← 截断后缀
```

---

## 8. 深色模式

### 8.1 现状

整个 App **强制深色** (`.preferredColorScheme(.dark)`)：

```swift
RootView()
    .preferredColorScheme(.dark)
```

### 8.2 决策原因

1. 产品文档明确：「记录灵感常在夜间，深色模式降低视觉干扰」
2. 减少跨模式 QA 工作量（v0.x 阶段）
3. 与品牌"温柔克制"调性一致

### 8.3 v1.0 后的考虑

未来若开放 Light/Auto 切换：

- 把强制深色挪到「偏好 → 主题」开关
- AccentColor 已是 P3 色值，自动适配
- 检查 `.white.opacity(0.04)` 这种叠加层 —— 浅色模式需改为 `.black.opacity(...)`
- 检查所有硬编码的 `.foregroundStyle(.white)` 改为 `.primary`

---

## 9. 触控目标

最小 44×44pt（Apple HIG 规范）。

实际项目中：

| 元素 | 实际触控区 |
|---|---|
| 工具按钮 | 36×36 视觉 + Button hit area 自动扩展 |
| 列表行 | 整行可点（背景 + `contentShape(Rectangle())`） |
| capsule chip | padding 12×6 + 文字 ≥ 18px → 总高 ≥ 30px |
| 头像 | 48×48 大头像 / 36×36 中头像 / 20×20 小头像（仅展示，不点） |

**铁律**：可点元素都要 `contentShape(Rectangle())`，否则只在文字本身可点。

---

## 10. 不做清单（重要）

避免常见的设计陷阱，**这些事情我们主动选择不做**：

| 不做 | 原因 |
|---|---|
| 不用渐变文字 | 影响可读性 + 与"克制"理念冲突 |
| 不用阴影做卡片悬浮 | 深色模式下阴影几乎看不到 + 增加渲染成本 |
| 不用过度模糊（`blur(radius: > 60)`） | iOS 模糊性能成本高，仅引导大圆光环用了 40 |
| 不滥用 emoji | UI 元素用 SF Symbols，emoji 仅作内容性标签 |
| 不用动态字体（自定义 ttf） | 系统苹方足够，引入字体增加 App 体积 |
| 不全局加载头像 | 用 `AvatarView` 派生稳定颜色 + 首字母占位，无图也好看 |
| 不用 Storyboard | iOS 17+ 推荐 `UILaunchScreen` plist 配置 |

---

## 11. 检查清单（新页面 PR 时自查）

- [ ] 字体用 Dynamic Type 标准号，未硬编码 size
- [ ] 颜色用语义色（`.primary` / `.secondary` 等），未自定灰阶
- [ ] spacing 是 4 的倍数
- [ ] 圆角符合形态分类（卡片 12-14 / 头像 Circle / 胶囊 Capsule）
- [ ] 动效尊重 `accessibilityReduceMotion`
- [ ] 装饰元素 `accessibilityHidden(true)`
- [ ] 复合行用 `accessibilityElement(children: .combine)`
- [ ] 触控目标 ≥ 44×44 实际 hit area
- [ ] 文案中文标点 / 数字前后留空格 / 用「」
- [ ] 空态有 CTA 或 hint，不让用户发呆
- [ ] 图标用 SF Symbols，未用 emoji 占 UI 位

---

## 致设计同行

这份指南是从代码反推、提炼出的**实然规范**，不是架空的理论。
每条规则在仓库里都能找到至少 3 处实例落地。

如果你要做一个**违反这些规则**的页面 —— 说明这个规则该被挑战了。
不要默默改成与众不同的样子，请：
1. 提一个 PR 同时改这份文档
2. 在 PR 描述里说明为什么旧规则在新场景下不适用
3. 给团队 review 的机会

让风格保持一致，比让某一处变好看，重要得多。

— 拾忆设计与开发团队
