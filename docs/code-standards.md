# 代码规范

> 状态：🚧 规划中。本规范面向 Flutter（Dart）实现，业务规则部分继承自 cent-xyx 的经验总结。

## 1. 核心业务规范（最高优先级）

以下规范违反会导致数据错误，必须严格遵守：

| # | 规范 | 说明 |
|---|------|------|
| 1 | **金额一律整数万分之元** | 1 元 = 10000。UI 层 `amount / 10000`，输入/存储 `amount * 10000`。所有 Service/Repository 接口入参出参统一此单位 |
| 2 | **禁止绕过 Service 修改 `currentBalance`** | 余额变动只能通过 `AccountService` 的方法（记账联动 / 手动调账） |
| 3 | **账户/快照修改后同步写回 meta** | 数据库是唯一事实来源，任何账户/快照变更与 meta 中的 `accounts` / `balanceSnapshots` 保持一致 |
| 4 | **调账账单必须 `extra.isAdjustment = true`** | 否则会被余额重算错误累加 |
| 5 | **新增自定义分类必须 `customName = true`** | 用于区分默认分类与用户自定义 |
| 6 | **导入账单必须打来源标记** | `extra.isYimu` / `isZhouhu` / `isQianji`，余额重算与校验时跳过 |
| 7 | **快照 `billId` 必须与最终账单 ID 一致** | 先确定 ID 再写库，保证快照失效逻辑可用 |

## 2. 语言与格式化

- 遵循 `dart format`（官方风格），提交前必须格式化。
- 开启 `flutter analyze`，目标 **0 error，0 warning**。
- 禁止用 `// ignore:` 大面积压制告警；确有理由时写注释说明。
- 命名：
  - 文件：`snake_case.dart`（如 `account_service.dart`）
  - 类/枚举/类型：`PascalCase`
  - 方法/变量：`camelCase`
  - 常量：`camelCase`（Dart 风格，非大写蛇形）
  - 私有：前缀 `_`

## 3. 目录与分层

- 严格分层：`ui → state(providers) → domain(services) → data(repositories/database)`。
- **UI 层禁止直接访问数据库**，一律通过 Repository / Provider。
- **领域层不依赖 Flutter UI 库**（可单测）。
- 依赖方向单向：外层依赖内层，禁止反向。

## 4. 状态管理规范（Riverpod）

| 场景 | 推荐 |
|------|------|
| 全局偏好（主题、语言、默认账户） | `SharedPreferencesAsyncProvider` |
| 当前账本、账单列表 | `AsyncNotifier` / `StateNotifier` |
| 账户、快照 | `AsyncNotifier`，只读缓存数据库 |
| 一次性事件（导入、同步进度） | 局部 State + Stream |

约定：
- Provider 只做缓存与派生，**不持有业务逻辑**；写操作调用 Service。
- 大数据量列表使用分页 / 懒加载，不一次性载入全量。

## 5. 数据库规范（drift）

- 表定义集中在 `lib/data/database/tables/`。
- 每个账本一个数据库文件 `book-<id>.db`。
- **所有结构变更走 MigrationStrategy**，禁止删库重建（避免用户数据丢失）。
- 金额字段用 `INTEGER`（万分之元），时间用 `INTEGER`（毫秒时间戳）。
- 修改表后重跑：`dart run build_runner build --delete-conflicting-outputs`。

## 6. 多语言规范（i18n）

- 词条位于 `lib/l10n/*.arb`，`flutter gen-l10n` 生成。
- **词条数量各语言必须一致**（zh/en 一一对应）。
- **原词条不可动**：默认已由翻译公司维护，除非明确授权不得修改/删除/插入原词条。
- **改文案 = 新增词条**：原 key + `V2`（再改用 `V3`）后缀，新增在文件底部。
- 占位符 `{placeholder}` 内部不允许翻译或改动。

## 7. 错误处理

- 业务异常定义在 `core/exceptions/`，继承 `XupurseException`，携带面向用户的 i18n 文案。
- Service 抛出领域异常，UI 层统一捕获并 toast/snackbar 展示。
- 禁止 `catch (e)` 后静默吞掉错误；导入等重操作需记录日志（`dart:developer` / logger）。

## 8. 日志规范

- 使用 `debugPrint` / 统一 logger，生产环境自动降级。
- **禁止打印敏感数据**（完整备注、卡号、token）。
- 关键操作（导入、调账、余额重算、删除账本）必须有结构化日志。

## 9. Git 提交规范

### 9.1 提交信息格式（Conventional Commits）

```
<type>(<scope>): <description>

例：
feat(accounts): 支持历史快照手动添加
fix(import): 修复一木导入重复累加余额
refactor(storage): 迁移账户存储到账本数据库
```

| type | 用途 |
|------|------|
| feat | 新功能 |
| fix | Bug 修复 |
| refactor | 重构（不改变行为） |
| perf | 性能优化 |
| docs | 文档 |
| test | 测试 |
| chore | 构建/杂项 |

### 9.2 提交规则（用户明确约定）

1. **不要主动问是否 commit / push**。
2. **禁止 AI 自行执行 `git push`**；push 只能由用户自己操作。
3. `git commit` 仅在用户明确许可时执行，且**许可仅当次有效**，后续需重新授权。
4. commit 前先 `dart format` + `flutter analyze` 通过。

## 10. 测试规范

- 金额换算、汇率公式、余额计算、调账、导入映射、diff 等**纯逻辑必须单测**。
- 关键路径（记账联动余额、删除撤销、快照失效）写 widget/集成测试。
- 测试命名：`should_<行为>_when_<条件>`（如 `should_deduct_balance_when_expense_added`）。
