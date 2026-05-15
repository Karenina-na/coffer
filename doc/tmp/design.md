# DESIGN.md（历史参考）

> **注意**：本文件为早期设计参考（海军蓝金融科技主题）。实际实现已演变为**深色单色灰主题**（见 `lib/core/ui/design_tokens.dart`，注释标明 "Derived from doc/tmp/DESIGN.md"）。
>
> **仍有效的部分**：间距刻度（4/8/12/16/20/24/32/40）、语义色（positive `#22C55E` / negative `#EF4444` / warning `#F59E0B`）、信息架构与路由约定、安全显示规则、组件分层原则。
>
> **已偏离的部分**：核心色板（海军蓝 → 单色灰）、字体栈（IBM Plex Sans + JetBrains Mono → PingFang SC + Menlo）、阴影层级（未落地）。
>
> 当前实现的设计令牌参考 `lib/core/ui/design_tokens.dart` 中的 `GwpColors` / `GwpTypo` / `GwpSpacing`。

---

> Project: GWP 个人金融资产管理 App  
> UI 目标：高可用 + 高信息密度 + 专业金融科技风（Institutional Fintech）  
> 本文件定义视觉与交互基线；信息架构与路由以 `doc/ui-navigation.md`（你的现有文档）为准。
---
## 1. Visual Theme & Atmosphere
### 1.1 设计气质
- 关键词：**严谨、可信、克制、数据驱动、专业**
- 风格方向：深色专业控制台（非交易炫技风），强调可读性与决策效率。
- 视觉优先级：**数据清晰度 > 装饰性 > 动效表现**
### 1.2 IA / 导航不变约束（必须遵守）
- 底部 5 个主 Tab：`/dashboard` `/holdings` `/events` `/rates` `/cards`
- `/holdings` 为二级 Tab 工作台：`账户 / 资产 / 转账`
- 列表/概览在 Shell 内；创建/详情/设置在 Shell 外
- 卡片详情、事件详情优先走 Bottom Sheet，保留上下文
### 1.3 体验原则
- “一屏可扫读”：用户在 3–5 秒内识别关键变化（盈亏、风险、缺失汇率、待处理事项）
- “动作可直达”：关键问题必须有一跳操作（例如缺失汇率 -> `/rates`）
- “状态可解释”：所有失败/拦截/降级必须显示原因与下一步
---
## 2. Color Palette & Roles
> 暗色主主题，保留浅色主题能力；语义色用于状态，不用于大面积装饰。
### 2.1 Core Tokens
| Token | Hex | 用途 |
|---|---|---|
| `color.bg.canvas` | `#0A0F1C` | 全局背景 |
| `color.bg.surface.1` | `#11192B` | 一级容器（主卡片） |
| `color.bg.surface.2` | `#16233A` | 二级容器（嵌套区块） |
| `color.bg.surface.3` | `#1B2A45` | 强调容器（高亮上下文） |
| `color.border.default` | `#2B3B58` | 默认边框 |
| `color.border.strong` | `#3A4E73` | 重点边框/分割 |
| `color.text.primary` | `#E8EEF9` | 主文本 |
| `color.text.secondary` | `#A9B7CF` | 次文本 |
| `color.text.muted` | `#7E8EA9` | 低权重说明 |
| `color.action.primary` | `#3E7BFA` | 主操作 |
| `color.action.primary.hover` | `#5A92FF` | 主操作 hover/pressed |
| `color.action.secondary` | `#243754` | 次操作背景 |
### 2.2 Semantic Tokens
| Token | Hex | 含义 |
|---|---|---|
| `color.state.positive` | `#22C55E` | 正收益 / 成功 |
| `color.state.negative` | `#EF4444` | 负收益 / 风险 |
| `color.state.warning` | `#F59E0B` | 警告 / 待处理 |
| `color.state.info` | `#38BDF8` | 信息 / 中性提示 |
### 2.3 使用规则
- 盈亏/风险信息必须“颜色 + 图标 + 文案”三重编码，不可只靠颜色。
- 高密度表格中避免彩色背景块泛滥，优先用文本色与小徽标表达语义。
- 对比度：正文与背景至少满足 WCAG AA（关键数字建议 AAA）。
---
## 3. Typography Rules
### 3.1 字体栈
- UI 文本：`"IBM Plex Sans", "PingFang SC", "Noto Sans SC", "Microsoft YaHei", sans-serif`
- 数字与金额：`"JetBrains Mono", "IBM Plex Mono", "SFMono-Regular", "Menlo", monospace`
- 图标：Material Symbols Outlined（与你路由图标系统一致）
### 3.2 字号与字重
| 语义 | 字号/行高 | 字重 |
|---|---|---|
| 页面标题 | `22/30` | 600 |
| 区块标题 | `16/24` | 600 |
| 主数值（KPI） | `28/34` | 700 |
| 表格主字段 | `14/20` | 500 |
| 表格次字段 | `12/18` | 400 |
| 说明/注释 | `12/16` | 400 |
### 3.3 数字展示规则（必须）
- 金额、汇率、比例全部右对齐（表头与内容一致）。
- 启用 `tabular-nums`，保证数值列垂直对齐。
- 负数格式统一：`-12,345.67`
- 百分比统一保留位数（默认 2 位）。
- 双币显示：第一行基准币（主），第二行原币（次，弱化）。
---
## 4. Component Stylings
## 4.1 App Shell
- Top AppBar：56dp，高对比文本，右侧搜索/动作图标不超过 3 个。
- Bottom NavigationBar：固定 5 项；标签简短、避免换行。
- 页面主体优先卡片化分区，减少视觉噪声。
## 4.2 KPI Card（仪表盘核心）
- 结构：标题 + 主数值 + 对比变化 + 辅助说明
- 主数值区可展示：净资产、当日盈亏、周期变化
- 点击区域完整可点（不仅数字可点）
## 4.3 Data Table（高密度核心组件）
- 桌面默认紧凑行高：`36–40px`
- 移动默认行高：`44px`
- 支持：固定表头、排序、筛选、列宽控制、行内状态标记
- 允许行展开显示次要字段，避免横向挤压
## 4.4 Tabs / Filter Bar
- 一级内容页内二级 Tab 固定于页面顶部（跟随滚动可吸附）
- 筛选条单行优先，超出折叠到“更多筛选”
- 过滤状态必须可见且可一键清空
## 4.5 Bottom Sheet（详情模态）
- 用于卡片详情、事件详情
- 展示顺序：关键摘要 > 关联实体跳转 > 扩展信息
- 跨模态跳转先关闭当前 sheet 再 push 详情页
## 4.6 Form / Input
- 输入框统一高 `40px`（紧凑）/ `44px`（舒适）
- 错误信息紧贴字段显示，附可执行建议
- 危险操作（删除、解绑）使用二次确认 + 强语义按钮
## 4.7 状态组件（统一）
- Loading：骨架屏（禁止全屏长时间转圈）
- Empty：图标 + 说明 + 主操作按钮
- Error：错误原因 + 重试按钮 + 兜底路径
- Partial Data：允许局部可用并明确标注“部分数据不可用”
## 4.8 安全显示（必须）
- 卡号/CVV 永不明文直接展示；默认 `•••• 1234`
- 明文查看需显式用户动作并有时间性约束（短时显示）
---
## 5. Layout Principles
### 5.1 栅格与间距
- 桌面：12 栏栅格，gutter `16px`
- 平板：8 栏栅格，gutter `12px`
- 手机：4 栏栅格，gutter `8px`
- 基础间距刻度：`4, 8, 12, 16, 20, 24, 32, 40`
### 5.2 密度模式
- `Compact`（默认）：专业用户、日常监控
- `Comfortable`：移动端与新手友好
- 同一页面内不要混用两套密度（除弹层/表单特例）
### 5.3 页面模板（按你的 IA 固定）
- `/dashboard`：净资产卡 + 统计摘要 + 缺失汇率提示 + 快捷入口
- `/holdings`：二级 Tab 工作台；账户/资产列表高密度，转账显示路径规划结果
- `/events`：时间倒序事件流，支持关联实体一跳打开
- `/rates`：快照列表 + 管理币对 + 拉取最新 + 手动录入
- `/cards`：卡片列表 + 详情弹层 + 关联账户跳转
---
## 6. Depth & Elevation
- 以“边框层级”优先于“重阴影”。
- 阴影仅用于浮层与弹窗，不用于普通列表行。
- 层级建议：
  - `elevation-0`：页面背景
  - `elevation-1`：普通卡片
  - `elevation-2`：悬浮组件（下拉、popover）
  - `elevation-3`：模态（Bottom Sheet / Dialog）
---
## 7. Motion & Interaction
- 动效节奏：`120ms`（微交互）/ `180ms`（组件过渡）/ `240ms`（页面切换）
- 曲线：以 `ease-out` 为主，避免弹跳与夸张缩放
- 列表刷新与筛选变化：优先渐变/位移，不做复杂转场
- 所有动作反馈必须在 100ms 内出现视觉响应（高亮、loading、pressed）
---
## 8. Do / Don’t
### Do
- 保持信息密度高但层级清晰（主次字段、颜色权重明确）
- 关键数字永远可快速定位（对齐、同位、稳定）
- 任何“异常状态”都给出下一步动作
- 跨实体字段保持可点击，避免信息死胡同
### Don’t
- 不做营销化大插画占屏
- 不使用大面积渐变背景干扰数据阅读
- 不把关键状态藏在 tooltip 里
- 不只用颜色表示盈亏/风险
- 不让用户在模块之间反复跳转才能完成一个任务
---
## 9. Responsive Behavior
### 9.1 Breakpoints
- `mobile`: `< 600`
- `tablet`: `600–1023`
- `desktop`: `>= 1024`
### 9.2 自适应规则
- 移动端优先保留：关键 KPI、主表前 4–6 列、核心操作
- 次要字段收纳到行展开或详情弹层
- 桌面端允许双栏/三栏并行，提高监控效率
- 底部导航在移动端常驻；桌面端可切侧边导航（保持同路径语义）
---