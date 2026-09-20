# UI Design System

## Bright Luminous Minimalism

本项目采用 **Bright Luminous Minimalism（明亮光感极简）** 作为整体视觉与交互设计语言。

核心关键词：

**明亮 / 活泼 / 高级 / 克制 / 灵动 / 易读 / 统一**

目标不是制造大量视觉特效，而是通过 **排印、比例、留白、色彩、光影、连续曲线和统一动效**，建立一个有明显设计感、但长期使用仍然舒服的个人记账工具。

---

# 1. Overall Visual Direction

整体采用浅色视觉，不使用暗色作为主要基调。

视觉氛围参考：

> **采光优秀的现代建筑内部。**

可以有柔和的环境光、局部色彩、光晕和模糊，但不出现明显的“玻璃材质感”。

高级感主要来自：

* 清晰的 Typography Hierarchy
* 严格的 Spacing / Grid
* G2 / Smooth Corner Shape Language
* 分层明确的 Elevation
* 克制但鲜艳的 Accent Color
* 柔和环境光
* 统一、自然的 Motion Language

而不是来自：

* 大量透明玻璃
* 黑色背景
* 大面积渐变
* 复杂装饰
* 过度阴影
* 炫技式动画

整体最终观感应该是：

> **明亮、有活力、有空间感、有设计感，但信息始终比装饰更重要。**

---

# 2. Typography System

Typography 是本项目最重要的视觉基础之一。

记账 App 的核心信息是：

**金额、日期、分类、描述、统计数据。**

因此 Typography 必须同时满足：

**高可读性 + 数字对齐 + 清晰层级 + 足够的高级感。**

## 2.1 Font Family

优先使用平台系统字体。

iOS / macOS：

* SF Pro / 系统中文字体

Android：

* 系统 Sans Serif

中文与英文应尽量保持自然的字面高度与视觉重量。

不为了“设计感”强行使用装饰性字体。

---

## 2.2 Type Scale

项目统一使用有限的字号阶梯。

基础刻度：

| Token      |  Size |  Weight | 用途                   |
| ---------- | ----: | ------: | -------------------- |
| Display    | 32–36 |     700 | 页面核心金额 / 极少量 Hero 信息 |
| H1         |    28 |     700 | 页面主要标题               |
| H2         |    22 |     600 | 大区块标题                |
| H3         |    18 |     600 | 卡片 / 小区块标题           |
| Body Large |    16 | 400/500 | 核心正文                 |
| Body       |    14 | 400/500 | 普通正文                 |
| Caption    |    12 | 400/500 | 辅助说明                 |

不要随意创造 17、19、21、23 等零散字号。

除特殊视觉需求外，所有 Text 应优先来自 `TextTheme` / Typography Token。

---

## 2.3 Financial Number Typography

金额是本项目最重要的文字信息。

所有需要纵向或横向比较的财务数字必须使用：

**Tabular Figures / 等宽数字**

保证：

```text
¥ 1,280.00
¥   820.50
¥ 9,180.20
```

数字列可以稳定对齐。

金额强调主要通过：

**Font Weight > Font Size**

而不是单纯不断增大字号。

例如：

```text
Primary Amount
32px / Weight 700

Secondary Amount
20px / Weight 600

Normal Amount
16px / Weight 500
```

不要为了强调一个数字就使用过大的字号。

---

## 2.4 Text Style Source

所有页面必须优先使用：

* Theme Typography
* Typography Tokens
* Financial Number Styles

禁止在业务页面大量直接创建裸 `TextStyle`。

例如不要：

```dart
TextStyle(
  fontSize: 17,
  fontWeight: FontWeight.w600,
)
```

而应该：

```dart
AppTextStyles.amountPrimary
```

或：

```dart
Theme.of(context).textTheme...
```

这样 Typography 可以集中调整。

---

# 3. Spacing & Grid System

项目已经存在 `XpSpacing`，其基础刻度应正式升级为全局 Design Token。

## 3.1 Base Spacing Scale

基础刻度：

```text
4
8
12
16
24
```

主要用途：

| Token | 用途                      |
| ----- | ----------------------- |
| 4     | 极小间距 / Icon 与文字         |
| 8     | 紧密内容                    |
| 12    | 小组件内部                   |
| 16    | 标准组件内边距 / 普通列表          |
| 24    | Card / Section / 页面主要区块 |

如确实需要更大的结构间距，可增加：

```text
32
```

但不能随意引入大量非 token 数值。

---

## 3.2 Spacing Principle

视觉高级感主要来自：

**重复、统一、可预测的间距比例。**

例如一个 Card 内部：

```text
16
标题
8
内容
12
辅助信息
16
```

而不是：

```text
13
标题
17
内容
11
辅助信息
19
```

除非存在明确的视觉设计原因，否则禁止任意设置 Padding / Margin。

---

## 3.3 Page Grid

移动端页面默认：

```text
Horizontal Page Padding = 16
```

重要 Hero / Dashboard 区域可以扩展到：

```text
24
```

同一页面中的主要内容必须尽量对齐到统一的左右基线。

---

# 4. Color System

颜色分为：

```text
Base
↓
Brand
↓
Semantic
↓
Category
↓
Decorative
```

而不是把所有鲜艳颜色直接放进一个 Palette。

---

## 4.1 Base Color

默认浅色基础：

```text
Background
#F7F8F6

Surface
#FFFFFF

Surface Secondary
#F2F4F5

Primary Text
#18212B

Secondary Text
#66717D

Tertiary Text
#929BA5
```

颜色整体保持明亮、干净。

避免纯黑文字和纯白大面积背景产生过强对比。

---

# 5. Brand Accent

整个 App 必须有一个明确的：

**Brand Primary Color**

它负责品牌识别。

建议采用：

```text
Primary Brand
Violet / Blue-Violet
```

例如：

```text
#6757E8
```

或者根据实际 App Logo / 品牌色调整。

Brand Primary 用于：

* Primary Button
* 当前选中状态
* 强调链接
* Navigation Active
* 主要交互
* 部分环境光

它不能与“收入 / 支出”等财务语义颜色混用。

---

# 6. Financial Semantic Colors

必须明确统一：

### Income

```text
Green
#20B978
```

用于：

* 收入
* 增加余额
* 正向现金流

### Expense

```text
Coral / Red
#F0645A
```

用于：

* 支出
* 减少余额
* 消费相关统计

### Transfer

```text
Blue / Cyan
#3E9FE8
```

用于：

* 转账
* 账户间流动
* 中性资金流

### Warning

```text
Amber
#E7A92B
```

### Error

```text
Red
#E05454
```

### Success

默认复用 Income Green，避免出现过多绿色体系。

---

# 7. Category Colors

财务分类颜色可以使用独立的 Category Palette。

Category Color 不应该直接占用 Brand / Income / Expense / Transfer 的语义颜色。

例如：

```text
Food        Coral
Shopping    Violet
Transport   Blue
Entertainment Yellow
Health      Green
Bills       Cyan
Other       Gray
```

Category Palette 可以根据具体业务重新调整。

原则：

> **颜色表达“分类”，而不是表达“状态”。**

---

# 8. Accent Usage Rules

整个屏幕中：

**主要 Accent 不超过 2–3 个。**

不要在一个页面同时让：

```text
Blue
Purple
Cyan
Green
Yellow
Orange
Red
```

全部抢视觉注意力。

建议：

### 主要页面

```text
1 Brand Accent
+
1–2 Semantic / Category Accent
```

### 图表

可以使用更多颜色，但必须遵守：

**颜色服务于数据，不服务于装饰。**

---

# 9. Light / Blur System

Blur 的作用：

**制造空间中的光。**

不是：

**制造玻璃材质。**

因此：

## 可以 Blur

* Background
* Ambient Glow
* Bloom
* Bottom Sheet 后面的内容
* 页面装饰光
* Transition 背景

## 不应该 Blur

* 核心金额
* 主要文字
* 重要数据 Card
* 主要输入控件

---

# 10. Ambient Lighting

允许使用：

* Soft Radial Gradient
* Large Gaussian Blur
* Bloom
* Vertical Light Field

例如：

```text
淡紫光
     ↓
淡蓝光
     ↓
透明
```

但光源必须非常柔和。

用户应该感受到：

> “这个页面光线很好。”

而不是：

> “这个页面有很多渐变。”

---

# 11. Elevation System

项目统一使用三层 Elevation。

## E0 — Flat

用于：

* 页面背景
* 普通区域
* 无需强调的内容

无明显阴影。

---

## E1 — Card

用于：

* 普通 Card
* List Container
* Summary Card

特点：

* 极浅
* 大 Blur
* 大 Spread
* 小 Offset

阴影色温偏：

**冷灰 / 蓝灰**

而不是纯黑。

示意：

```text
Color:
cool blue-gray with low alpha

Blur:
20–28

Offset Y:
4–8
```

视觉目标：

> Card 看起来只是比背景“稍微脱离”一点。

---

## E2 — Floating

用于：

* Dropdown
* Popup
* Floating Action
* 临时浮层

阴影比 E1 稍强：

```text
Blur:
28–36

Offset Y:
8–12
```

仍然保持柔和。

---

## E3 — Sheet / Major Overlay

用于：

* Parameter Sheet
* Action Sheet
* Major Dialog

特点：

* 大范围
* 柔和
* 冷灰蓝
* 高于普通 Card

它表现的是：

**“空间层级发生变化”**

而不是：

**“这里有一个黑色阴影”。**

---

# 12. Shape Language

整个项目统一使用：

**Smooth Continuous Corner / G2-like Corner Language**

形状必须在全项目保持一致。

建议定义：

```text
Large Surface
Radius 28
Smoothness 0.8–1.0

Medium Surface
Radius 20
Smoothness 0.8

Small Surface
Radius 14
Smoothness 0.6–0.8

Control
Radius 12
Smoothness 0.6
```

具体参数可以经过视觉 Demo 再统一微调。

---

## 12.1 Implementation Requirement

不要把：

```text
BorderRadius.circular(...)
```

直接散落到业务代码。

统一通过：

```text
AppShape
```

或者：

```text
AppRadii
AppShapeTokens
```

管理。

---

## 12.2 Flutter Implementation

如果项目要求的是接近 Figma corner smoothing 的视觉效果，应明确指定实际 Shape 实现。

`ContinuousRectangleBorder` 可以提供连续过渡的圆角形状，但它不应直接作为“Figma G2 / corner smoothing”的同义词。Flutter 当前也提供 `RoundedSuperellipseBorder` / `RSuperellipse`，但如果设计系统需要明确控制 Figma-style `cornerSmoothing`，应优先使用专门的 smoothing 实现。

推荐统一封装：

```text
SmoothShape
```

底层可以使用：

```text
figma_squircle
```

并将：

```text
cornerRadius
cornerSmoothing
```

作为 Design Token，而不是由业务代码直接控制。

这样未来即使更换底层 Shape 实现，也不需要修改业务页面。

---

# 13. Component Language

组件必须建立统一视觉和交互语义。

核心组件包括：

```text
Button
Card
Icon Button
Input
Switch
Checkbox
Segmented Control
Tab
Dropdown
Parameter Sheet
Confirm Dialog
Action Sheet
Toast
Loading
Empty State
```

相同语义必须使用相同组件。

禁止不同页面重新实现一套视觉类似但行为不同的组件。

---

# 14. Standard Parameter Sheet

所有“参数设置类”操作统一使用：

**Parameter Sheet**

默认：

```text
Height ≈ 80% Screen
Position = Bottom
Surface = Opaque
Shape = Large Smooth Corner
```

进入：

```text
Bottom → Final Position
Opacity 0 → 1
Background Blur 0 → Max
```

退出：

```text
Final Position → Bottom
Background Blur Max → 0
```

关键原则：

**Sheet Translation 与 Background Blur 使用同一个 Progress 驱动。**

即：

```text
progress = 0
Sheet at bottom
Blur = 0

progress = 1
Sheet at final position
Blur = Max
```

拖动时二者实时同步。

因此用户能够直接感知：

> Sheet 正在进入 / 离开当前空间。

---

# 15. Dialog / Confirmation

Confirm Dialog 不使用 Parameter Sheet 的行为。

用于：

* 删除
* 覆盖
* 重要操作确认
* 风险操作

特点：

* 居中
* 尺寸较小
* 动画快速
* 背景轻微 Blur
* 明确 Primary / Secondary Action

它应该让用户感觉：

> “系统正在等待我的明确决定。”

而不是一个普通参数页面。

---

# 16. Motion System

整个 App 使用统一 Motion Language。

原则：

> **Every interaction should have feedback, but no animation should call attention to itself.**

即：

**每一次操作都有反馈，但动画不能抢走内容本身的注意力。**

---

## Micro Motion

用于：

* Button
* Switch
* Icon
* Press Feedback

```text
120–220ms
```

轻微：

* Scale
* Position
* Opacity
* Color

---

## Component Motion

用于：

* Card
* Menu
* Selector
* Dropdown

```text
180–300ms
```

---

## Container Motion

用于：

* Bottom Sheet
* Dialog
* Action Sheet

```text
280–420ms
```

---

## Page Motion

用于：

* Page Enter
* Page Exit
* 大范围内容切换

```text
300–500ms
```

---

# 17. Motion Characteristics

动画默认：

* 非线性
* 有自然减速
* 有适量 Spring
* 尽量跟手
* 避免明显弹跳

禁止为了“高级”而：

* 大幅旋转
* 大幅缩放
* 复杂 3D
* 长时间动画
* 大面积飞入飞出
* 多层同时剧烈运动

动画应该让 UI：

**灵动**

而不是：

**炫技。**

---

# 18. Page Transition

页面进入默认：

```text
Opacity:
0 → 1

Translate Y:
8–16 → 0
```

配合自然非线性曲线。

页面退出使用反向动画。

避免所有页面都使用完全不同的 Transition。

---

# 19. Interaction Consistency

同一种行为必须拥有同一种反馈。

例如：

所有参数设置：

```text
Bottom Sheet
```

所有 Switch：

```text
统一 Track / Thumb / Spring
```

所有页面：

```text
统一 Page Transition
```

所有按钮：

```text
统一 Press Feedback
```

所有拖动组件：

```text
统一跟手原则
```

目标：

> **让用户通过过去的交互经验直接预测当前 UI 的行为。**

这就是本项目的“直觉操作感”。

---

# 20. Design Token Rule

所有视觉属性必须尽量 Token 化。

至少包括：

```text
AppColors
AppTextStyles
AppSpacing
AppRadii
AppShapes
AppElevation
AppMotion
AppBlur
```

业务代码不应该直接散落：

```text
fontSize: 17
color: ...
borderRadius: 19
padding: 13
duration: 257ms
```

而应该：

```text
AppTextStyles.body
AppSpacing.md
AppShapes.card
AppElevation.card
AppMotion.component
```

这样 AI 后续重构页面时，只是在 Design System 中组合组件，而不是重新创造视觉规则。

---

# 21. Final Visual Goal

最终效果应该是：

**明亮**

不是苍白。

**活泼**

不是儿童化。

**高级**

不是冷淡。

**简约**

不是单调。

**有光感**

不是玻璃拟态。

**有动画**

不是炫技。

**有统一性**

不是机械模板化。

最终用户应该感觉：

> **“这是一个很漂亮、很舒服，而且我每天用起来很自然的记账 App。”**
