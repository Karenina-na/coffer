# AGENTS.md

面向 AI 编程代理（Comate / Claude / Cursor 等）的工作规约。人类开发者入门请读 `README.md`；本文件只收录「代理必须遵守」的硬约束。

---

## 1. 项目速览

- Flutter 3.41（实测 3.41.7）+ Dart SDK `^3.11.5`
- 平台范围：**Android 为主要验证平台**（强制走 §3 工作流）；iOS 目录保留但**当前不强制构建 / 不验证**，代理改动 iOS 相关代码需显式告知用户
- **本地优先**：全量数据落 Drift + SQLCipher；不得引入任何需联网的后端依赖
- 对外网请求只允许：Frankfurter（汇率）、东方财富 `push2.eastmoney.com` / `push2his.eastmoney.com`（国内主流股票优先）、Yahoo Finance `/v8/finance/chart`（加密 / 贵金属 / 海外兜底）
- 分层：`presentation → domain ← data`，domain 零外部依赖
- 金额：`package:decimal` 的 `Decimal`，**永远禁止 double**
- 敏感字段（卡号 / CVV）：AES-GCM，主密钥在平台 Keystore / Keychain
- `analysis_options.yaml` 基线：`package:flutter_lints/flutter.yaml`，无额外自定义规则——`Decimal 强制` / `lib/dev 隔离` 等约束**靠代理自律 + 人工 review**，没有 lint 兜底

## 2. 常用命令

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 改 freezed / drift 表后必跑
flutter analyze                                            # 必须 0 issue
flutter test                                               # 必须全绿
flutter build apk --debug                                  # Android debug 产物
flutter build apk --release                                # Android release 产物（必须一并跑）
```

## 3. 强制工作流（编译 → 安装 → 验证）

> **每次代码改动完成后，必须走完整条链，不可跳过安装步骤。**

1. `flutter analyze` → 0 issues
2. `flutter test` → 全部 pass（不允许带着失败测试提交）
3. `flutter build apk --debug` → 成功产出 `build/app/outputs/flutter-apk/app-debug.apk`
4. `flutter build apk --release` → 成功产出 `build/app/outputs/flutter-apk/app-release.apk`
   - debug 与 release **都要构建**，不可只跑其一
   - release 首次会从 GitHub 下载 SQLite3MultipleCiphers 原生二进制（arm/arm64/x64），遇到 `HttpException` 先重试再考虑网络环境
5. **安装到模拟器（强制，debug 包）**：
   ```bash
   $ANDROID_HOME/platform-tools/adb install -r \
     build/app/outputs/flutter-apk/app-debug.apk
   ```
   - 路径可能因环境而异；若 `adb` 不在 PATH，macOS 优先使用 `~/Library/Android/sdk/platform-tools/adb`，WSL2 使用 `$ANDROID_HOME/platform-tools/adb`
   - **WSL2 环境**：且必须 `env -u ADB_SERVER_SOCKET ADB_MDNS=0` 前缀于每个 adb 命令（见 §9 环境变量冲突）
   - 安装返回 `Success` 才算本次改动结束
   - 任何 UI / schema / 迁移改动**必须在模拟器实际验证**后再向用户汇报完成

Drift schema 变更额外要求：
- `schemaVersion` 递增 + `onUpgrade` 对应 `from < N` 分支
- 带实际数据的模拟器上安装 APK，观察启动不崩溃后再算通过

## 4. 代码约束

| 约束 | 强制理由 |
| --- | --- |
| 禁止 `double` / `num` 承载金额 | 精度 |
| 禁止在 UI 层直接消费 Drift 行 | 分层 |
| 所有外部 IO 经 Provider 接口 | 可测试 |
| freezed 实体默认不可变，修改走 `copyWith` | 数据一致 |
| 新增领域事件必须提供 `sourceKey`（幂等键）| 去重 |
| 事件若来自系统自动流程，`ackRequirement = NOT_APPLICABLE` | 避免打扰用户 |
| `lib/dev/` 仅限 debug；允许被 `kDebugMode` 门控后条件引用（如 `settings_page.dart` / `dashboard_page.dart`），靠 tree-shaking 从 release 剔除；**禁止在任何 release 可达路径上实际调用** | 安全 |

## 5. 目录定位（新增代码请落位）

```
lib/
├── app/                         # 路由 / 壳
├── core/                        # 横切：crypto / money / ui / result / errors
├── data/                        # Drift、Provider 实现、仓储实现
├── domain/                      # 实体 / 枚举 / 仓储接口 / UseCase / 事件
└── features/<name>/presentation # 页面 + Riverpod providers
```

- 新功能默认生成：`domain/entities` + `domain/repositories` 接口 + `data/repositories` 实现 + `features/<name>/presentation`
- 跨 feature 的 UI 基础件统一丢 `core/ui/`
- **设置页 `lib/features/settings/` 只放 App 级全局项**；某功能的局部配置请做成该功能内部的二级 Tab，不进设置页

## 6. 测试基线

- 位置：`test/**/*_test.dart`，按层分目录
  - `test/core/`：横切工具（crypto / money / search ranking）
  - `test/data/`：Drift schema + 迁移 + SQLCipher 集成
  - `test/features/`：领域 UseCase、Repository、页面 widget 测试
- 当前 41 个测试文件 / **386 个用例**（覆盖 crypto 加解密、money Decimal 精度、search ranking、Drift CRUD + migration smoke、SQLCipher 集成、明文 DB 文件头识别、event ack 幂等去重、asset valuator + TTL 缓存 + LRU 剪枝、UseCase 校验、repository soft-delete、backup 口令强度、auth_gate / PIN 流程、settings page、network error 摘要、FX 远端兜底缓存、refresh watched rates、refresh asset price、transfer asset、composite provider 熔断、Yahoo / Frankfurter / Eastmoney 外部响应校验、外网白名单约束等）
- Drift 相关用例使用内存 DB（`NativeDatabase.memory()`）
- 新增行为必须带测试；修改已有行为必须同步改测试断言
- 用例计数每次改动后要求同步更新本节数字（跟 `flutter test` 汇总行一致）

## 7. 文档联动

触及以下内容时，同步更新对应文档：

- 实体字段增减 / 枚举新增 → `doc/data-definitions.md`
- 分层或技术选型变化 → `doc/architecture.md`、README §技术栈
- ER 关系变化 → `doc/er-diagram.md`
- 里程碑完成 → README §实施进度勾选

## 8. 代理使用建议

- 删除功能时必须真正删代码，不留 `// removed` 这类墓碑注释
- freezed / drift 生成代码不要手工编辑；改源文件后跑 `dart run build_runner build --delete-conflicting-outputs`
- `flutter build apk --release` 当前使用 debug keystore 签名，仅用于 APK 功能验证，不是真正的生产发布包
- WSL2 模拟器必须用 x86_64 镜像（`system-images;android-34;google_apis;x86_64`），Apple Silicon 用 arm64-v8a

## 9. 失败兜底

- 本地 `adb` 缺失 → macOS 尝试 `~/Library/Android/sdk/platform-tools/adb`；WSL2 使用 `$ANDROID_HOME/platform-tools/adb`
- **WSL2 adb 命令挂起 / 超时** → 最常见原因是 `ADB_SERVER_SOCKET` 环境变量指向无效端口。每个 adb 命令必须加前缀 `env -u ADB_SERVER_SOCKET ADB_MDNS=0`；若仍失效，先 `killall -9 adb` 再重试
- **SQLite3MultipleCiphers 原生库下载失败（HandshakeException / 超时）** → GitHub 网络不通时需手动下载到 `.dart_tool/hooks_runner/shared/sqlite3/build/` 对应子目录（如 `download-4484332/`），并用 SHA256 校验；Android 构建时 hook 会分别为 arm64/arm/x64 下载，同理处理
- **Gradle daemon 构建卡住** → 先 `cd android && ./gradlew --stop`，然后用 `./gradlew assembleDebug --no-daemon 2>&1 | head -100` 观察实时进度；首次构建会下载 Android SDK Platform 35 / NDK 28 等，可能耗时 10 分钟以上
- Build Runner 报冲突 → 永远加 `--delete-conflicting-outputs`
- Drift 升级迁移失败 → 检查 `onUpgrade` 是否覆盖当前 `from` 区间，unique 索引需先建表再 `CREATE INDEX`
- Yahoo / Frankfurter / 东方财富 限流（429 / 5xx）→ 走 `MarketQuoteValuator` / Provider 内置 TTL 缓存，不要绕过；批量刷新（`RefreshAssetPriceUseCase.refreshAll`）当前**串行执行**，不可改为裸 `Future.wait` 并发（会触发限流）；如需加速必须带并发上限 + 退避
- 外部 API 字段改名 / schema 变化 → 解析层报错应转成 `AppError`，上层写入 `ASSET_VALUATION_FAILED` 事件，**禁止静默 fallback 到 0 / null 写进估值**

## 10. 版本控制 & 生成代码

- 当前工作区**未初始化为 git 仓库**；代理不得自行执行 `git init` / `git commit`，除非用户显式要求
- freezed / drift 生成的 `*.g.dart` / `*.freezed.dart` 属于构建产物，改动源文件后走 §2 的 `build_runner` 命令即可，不需要手工修改；代理不得直接编辑 generated 文件
- 用户如要求"提交代码"而 workspace 不是 git 仓库，代理应先询问仓库初始化策略，不要擅自决定
