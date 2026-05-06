# AGENTS.md

面向 AI 编程代理的工作规约。人类开发者入门请读 `README.md`；本文件只收录「代理必须遵守」的硬约束。

---

## 1. 项目速览

- Flutter 3.41.7 + Dart SDK `^3.11.5`，Android 为主要验证平台
- **本地优先**：全量数据落 Drift + SQLCipher；不得引入需联网的后端依赖
- 外网请求仅限：Frankfurter（汇率）、东方财富 `push2.eastmoney.com` / `push2his.eastmoney.com`、Yahoo Finance `/v8/finance/chart`、OKX API v5（加密货币现货+衍生品，免 Key）
- 分层：`presentation → domain ← data`，domain 零外部依赖
- 金额：`package:decimal` 的 `Decimal`，**永远禁止 double**
- 敏感字段：AES-GCM，主密钥在平台 Keystore / Keychain
- 当前 55 个测试文件 / 412 个用例

## 2. 常用命令

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 改 freezed / drift 表后必跑
flutter analyze                                            # 必须 0 issue（含 warning）
flutter test                                               # 必须全绿
flutter build apk --debug
flutter build apk --release
```

## 3. 强制工作流

> **每次代码改动完成后，必须走完整条链，不可跳过安装步骤。**

1. `flutter analyze` → 0 issues
2. `flutter test` → 全部 pass
3. `flutter build apk --debug` + `--release`（两个都要）
4. 安装到模拟器：`adb install -r build/app/outputs/flutter-apk/app-debug.apk`
   - Windows：`$env:ANDROID_HOME\platform-tools\adb` 或 `$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb`
   - 返回 `Success` 才算结束
5. **同步更新 `doc/` 文档**：若改动涉及实体字段、架构选型、外部 API、安全策略或 schema 版本变化，必须同步更新对应 doc 文件

> **开始任何任务前，必须先浏览 `doc/` 目录下的对应文档**，确认当前架构、数据模型与 UI 设计基线，避免基于过时假设做出改动。

Drift schema 变更额外要求：`schemaVersion` 递增 + `onUpgrade` 对应 `from < N` 分支 + 模拟器验证启动不崩溃。

## 4. 核心代码约束

| 约束 | 说明 |
| --- | --- |
| 禁止 `double` / `num` 承载金额 | `Decimal` 全程，仅在 fl_chart / UI 渲染的最终一步 `toDouble()` |
| `Decimal / Decimal` → `Rational` | **不是 Decimal**。百分比用 `(x * Decimal.fromInt(100) / y).toDecimal()` |
| 禁止在 UI 层直接消费 Drift 行 | feature 层通过 Riverpod provider → domain repository 接口访问 |
| 所有外部 IO 经 domain Provider 接口 | 不在 feature 内直接 `http.get` / `_dao.xxx` |
| freezed 实体不可变，修改走 `copyWith` | |
| 领域事件必须有 `sourceKey` | 幂等去重 |
| 系统自动事件 `ackRequirement = NOT_APPLICABLE` | 避免打扰用户 |
| `BankCard.toString()` 不得暴露 `cardNoCiphertext` / `cvvCiphertext` | 已添加显式重写掩码，新增敏感字段需同步更新 |
| mock_seeder 调用必须在 `if (kDebugMode)` 内 | tree-shaking 从 release 剔除 |

## 5. 目录定位

```
lib/
├── app/                         # 路由 / 壳（router.dart, theme.dart）
├── core/                        # 横切：crypto / money / ui / search / notifications
├── data/                        # Drift DAO、Mapper、仓储实现、Riverpod provider DI
├── domain/                      # 实体(freezed) / 枚举 / 仓储接口 / UseCase / 事件
│   └── providers/               # 跨 feature 的 domain 层 provider
└── features/<name>/presentation # 页面 + 本 feature 的 Riverpod provider
```

- 跨 feature 的 UI 组件 → `core/ui/`
- 设置页 `features/settings/` 只放 App 级全局项
- **已知债务**：`data/providers/dict_providers.dart` 被 6 个 feature 文件直接导入，这是 provider 作为 DI 配置的折中方案，不是重构遗漏

## 6. 测试约定

- 位置：`test/**/*_test.dart`，按 `core/` / `data/` / `features/` / `e2e/` 分层
- Drift 相关用例使用 `NativeDatabase.memory()`
- 新增行为必须带测试；修改行为须同步改断言
- widget 测试参考 `test/features/auth_gate_test.dart` 的 provider 覆盖模式，不要尝试启动完整 `CofferApp`（会触发 GoRouter + DB + AuthGate 全链路，需要太多 mock）
- 用例计数每次改动后同步更新 §1 数字

## 7. 常见陷阱

- **`Decimal / Decimal` 返回 `Rational`**：必须 `.toDecimal()` 或用乘后除模式 `(x * n / y).toDecimal()`
- **生成代码不要手工编辑**：改 freezed / drift 源文件后跑 `build_runner`
- **`flutter build apk --release` 使用 debug keystore**，仅用于功能验证
- **Android SDK 路径**：Windows 用 `$env:LOCALAPPDATA\Android\Sdk` 或 `$env:ANDROID_HOME`
- **`flutter analyze` 超时**：大型项目首次分析可能超 2 分钟，重试即可
- **BankCard freezed toString()** 由代码生成器自动包含所有字段，敏感字段需在源文件添加显式 `toString()` 重写掩码

## 8. 失败兜底

- **Build Runner 冲突** → `--delete-conflicting-outputs`
- **Gradle daemon 卡住** → `cd android && ./gradlew --stop`，然后重试
- **Drift 迁移失败** → 检查 `onUpgrade` 是否覆盖当前 `from` 区间，unique 索引先建表再 `CREATE INDEX`
- **外部 API 限流** → 走 `MarketQuoteValuator` / Provider 内置 TTL 缓存，批量刷新**串行执行**，不可改为裸 `Future.wait` 并发
- **API 解析失败** → 转成 `AppError` + 写 `ASSET_VALUATION_FAILED` 事件，禁止静默 fallback 到 0
- **SQLite3MultipleCiphers 下载失败** → 首次 release 构建从 GitHub 下载原生库，遇 `HttpException` 先重试

## 9. 版本控制

- 工作区是 git 仓库，但代理不得自行 `git commit`，除非用户显式要求
- 用户要求提交时，先 `git status` + `git diff` + `git log` 了解上下文，按现有 commit message 风格撰写
