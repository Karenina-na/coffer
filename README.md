# Coffer

> 项目目录与 Dart 包名仍保留 `gwp`（原开发代号 Global Wealth Platform）；
> 用户可见的应用名已升级为 **Coffer**。

本地优先的多账户 / 多资产 / 多卡种管理 App（Flutter，Android 主要验证，iOS 兼容构建）。

数据全部保存在设备本地，不依赖任何业务后端；敏感字段走 AES-GCM 字段级加密，主密钥托管于 Keychain / Keystore。外部网络调用仅用于公开元数据与行情拉取（Frankfurter 汇率、东方财富 / Yahoo / OKX 行情、REST Countries 国家地区元数据），不回传任何用户资产数据。

## 项目背景

Coffer 是一本运行在手机上的私密账本——不只是记账，而是把分散在多个银行账户 / 券商 / 银行卡 / 币种 / 地区的资产，整理成一张可审计、可追溯的全局财富视图。

### 核心问题

个人财务管理长期面临三个结构性痛点：

1. **资产碎片化**：银行账户、证券持仓、信用卡、定期理财分散在不同机构 App 中，缺乏跨机构、跨币种的统一视角。
2. **数据所有权缺失**：绝大多数理财工具依赖云端同步，用户的财务数据托管在服务商服务器上，存在隐私泄露和被平台锁定的风险。
3. **缺乏审计线索**：资产净值的历史变化、关键操作的时间线、估值依据等难以回溯，无法形成一条连贯的财务决策链条。

### 设计理念

- **本地优先**：全量数据落在设备端 SQLite 加密库，网络仅用于拉取公开行情，不传输任何用户私密数据。
- **领域事件溯源**：每一笔关键操作（资产创建、价格更新、账户变更等）均作为不可变事件持久化，形成完整审计链。
- **多币种原生支持**：以 `Decimal` 精度承载金额，按币种独立计价，跨币种通过汇率快照折算；不存在隐式 double 精度丢失。
- **安全纵深防御**：平台密钥存储（Keystore/Keychain）→ HKDF 用途派生 → 敏感字段 AES-GCM 字段级加密，三层防护确保即便数据库文件泄露也无法还原明文。

### 适用场景

- 持有多个银行 / 证券账户，需要跨机构统一查看总资产
- 涉及多种货币（人民币、美元、港币、日元、欧元等），希望按本位币折算净值
- 持有定期 / 固收产品，需要按实际计息规则动态估算当前价值
- 管理多张信用卡，需要跟踪账单日和还款日
- 对数据隐私敏感，拒绝将财务信息上传到任何云服务

## 设计文档

- `doc/data-definitions.md` — 核心实体字段定义
- `doc/er-diagram.md` — Mermaid ER 图
- `doc/architecture.md` — 分层架构、技术选型、实施路线

## 技术栈

- Flutter 3.41 + Material 3 + Dart 3.11
- 状态管理：Riverpod 3（`Notifier` / `FutureProvider.autoDispose` / `StreamProvider.family`）
- 路由：go_router
- 本地库：Drift + SQLCipher
- 加密：cryptography（AES-GCM 256）+ flutter_secure_storage（Keychain / Keystore）
- 生物识别：local_auth
- 金额：decimal（TEXT 入库，应用层 `Decimal`，**禁止 double**）
- 模型：freezed + json_serializable
- 图表：fl_chart
- 外部数据：`package:http`
  - Frankfurter（ECB 汇率快照 + 历史序列）
  - 东方财富 `push2.eastmoney.com` / `push2his.eastmoney.com`（A / H / 美 / 日 / 韩 / 英 / 欧股票 + 历史 K 线，免认证，国内直连优先）
  - Yahoo Finance `/v8/finance/chart`（加密 / 贵金属 / 期货 / 海外资产兜底）
- 本地通知：flutter_local_notifications（默认关闭，可在设置页内开启）

## 分层结构

```
lib/
├── app/                         # 路由、主题、壳
├── core/                        # 横切基础设施
│   ├── auth/                    # BiometricAuth
│   ├── crypto/                  # FieldCipher / KeyDerivation / SecureKeyStore / PasswordKDF
│   ├── money/                   # Decimal 解析、按币种格式化
│   ├── ui/                      # 共享 UI（EntitySearchDelegate 等）
│   ├── result.dart              # Result<T, E>
│   └── errors.dart              # AppError 分类
├── data/
│   ├── backup/                  # DbSnapshot（加密备份 / 恢复）
│   ├── db/                      # Drift 表、DAO、数据库实例
│   ├── providers/               # 外部数据源
│   │   ├── fx/                  # FrankfurterProvider + PriceProvider 接口
│   │   └── asset/               # YahooFinanceProvider + AssetPriceProvider 接口
│   ├── repositories/            # 各实体 Drift 仓储实现
│   └── crypto_service.dart
├── domain/
│   ├── entities/                # freezed 实体 + enum
│   ├── events/                  # DomainEventBus（内存总线 + 持久化投递）
│   ├── repositories/            # 仓储接口
│   └── usecases/                # Create*/Valuate*/Refresh*/Aggregate*/Simulate*/Backup*
└── features/
    ├── account/                 # 账户 列表 / 详情 / 新建 / 编辑
    ├── asset/                   # 资产 列表 / 详情（券商风格）/ 新建 / 编辑 / 价格刷新
    ├── card/                    # 卡片 Apple Wallet 风格 / 详情 sheet / 按需解密 / 新建 / 编辑
    ├── channel/                 # 转账通道管理 + 模拟报价 + 编辑
    ├── exchange_rate/           # 汇率列表 / 币对详情 / 管理币对
    ├── event/                   # 事件日历 + 列表 + Ack 流程 + 软删除
    ├── holdings/                # 「资金」页：账户 / 资产 / 转账 三 Tab
    ├── dashboard/               # 总览（Hero / KPI / 配置 / 趋势 / 账单 / 节点图 / 活动）
    ├── topology/                # 全景关系图
    ├── backup/                  # 备份 / 恢复
    ├── settings/                # App 级全局设置
    └── auth/                    # 生物识别 / 应用锁
```

依赖方向：`presentation → domain ← data`，Domain 不依赖任何外部框架。
UI 永远消费 freezed 领域实体，不直接接触 Drift 行对象。

## 已实现功能

### 实体 CRUD（全量覆盖）

所有实体均提供 **Create / Read / Update / Delete** 四种操作，UI 层入口统一为列表长按菜单或详情页 AppBar 编辑 / 删除按钮。

- **Account**：列表 / 详情（关联资产三栏视图 + 一键同步最新价）/ 新建 / 编辑（`/accounts/:id/edit`）/ 软删除 / 状态 Chip
- **Asset**：列表 / 券商风格详情页 / 新建 / 编辑（`/assets/:id/edit`）/ 软删除 / 自动 `marketValue = quantity × currentPrice` / 按账户过滤流
- **Card**：Apple Wallet 风格卡面 / 新建（卡号 + CVV 加密）/ 编辑（`/cards/:id/edit`，选择性替换卡号时重新加密）/ 硬删除 / 👁 按需解密显示卡号 / 详情 sheet
- **Channel**：转账通道规则引擎 + 模拟报价 / 新建 / 编辑（`/channels/:id/edit`）/ 启停切换 / 费率、限额、路径校验
- **Event**：日历视图 + 日内列表 + 软删除 + 完整领域事件审计 + Ack 流程（`ack_status × ack_requirement`）
- **ExchangeRate / WatchedPair**：关注币对 / 汇率快照 / 币对走势图 / 增删币对

### 行情刷新与估值

- **Frankfurter 汇率**：
  - `exchange_rate_list_page` 右上「一键同步 24h」拉取所有关注币对的最新快照
  - `pair_detail_page` 按当前区间（7 日 / 1 月 / 3 月 / 1 年 / 全部）拉取历史序列
- **Yahoo Finance 资产行情**：
  - `asset_detail_page` 支持「同步当前区间」：逐点写入 `asset_price_history` 审计表，事件表只收失败项
  - 股票 / 加密 / 期货 / 贵金属等统一走 Yahoo `chart` 端点；symbol 优先取 `asset.extInfo['priceSymbol']`，回退 `asset.assetCode`
  - 历史序列经由 `RefreshAssetPriceUseCase` 做单次 FX 换算后逐点写 `asset_price_history`（`source = 来源`）
- **缓存覆盖提示**：明细页切区间仅走 cache，若覆盖不足自动渲染 `_CoverageBanner` 警示条

### 仪表盘（多维度宏观视图）

- **Hero 净资产卡**：本位币可切换（CNY / USD / HKD / EUR / JPY / SGD / GBP）；带 delta chip（涨跌色 + 百分比 + 绝对值 + 区间标签）+ 范围感知 sparkline
- **KPI 网格 2×3**：账户 / 资产 / 活跃通道 / 信用额度（含利用率，>80% 转红）/ 待处理事件（含紧急计数）/ 缺失汇率
- **资产配置**：segmented 切换（按币种 / 按类型 / 按地区）+ 单 donut + Top 6 legend
- **净资产趋势**：7D / 1M / 3M / 1Y / ALL 切换；头部 4 栏关键统计（期初 / 期末 / 区间高低 / 变动%）+ 参考线 + tooltip
- **即将到来的账单**：信用卡账单日 / 还款日 45 天窗口，≤3 天转红；自动夹取月末无效日期
- **全球节点图**：按地区聚合账户 + 资产额，高亮转账通道
- **近期活动**：pending / triggered 事件优先，5 条滚动 feed
- **快捷入口**：新建账户 / 记录事件 / 转账通道 / 全景关系图 / 备份恢复

### 统一搜索

- 所有顶层页面 AppBar 右上 🔍 按钮，基于 `EntitySearchDelegate<T>`（`core/ui/entity_search_delegate.dart`）
- 每页不同的匹配字段：
  - 账户：机构 / 账号 / 地区 / 类型
  - 资产：代码 / 类型 / 币种
  - 卡片：掩码 / 发卡行 / 组织 / 类型 / 币种
  - 汇率：pairKey / 基准 / 报价币种
  - 事件：类型 / 关联 ID / 处理人 / 备注
- 每页预设过滤 Chip（`SearchFilterGroup`）从实际数据派生；group 间 AND、group 内 OR，再与关键词 AND，**输入即时返回结果**

### 安全与备份

- 字段级 AES-GCM：卡号 / CVV 仅以密文（Base64）入库；明文只存在于创建瞬间与「查看真实卡号」的临时内存
- 主密钥：首启生成 32B 随机密钥 → HKDF 派生用途子密钥（`field.card_no` / `field.cvv` / `backup.payload` / `db.sqlcipher`）
- 主密钥托管：Android Keystore / iOS Keychain（`first_unlock_this_device`）
- 应用锁：生物识别（`local_auth`）+ 口令兜底（`PasswordKDF`）
- 备份 / 恢复：手动文件型加密备份（`/backup` 备份中心）；导出包使用 Argon2id + AES-GCM，卡号可迁移恢复，CVV 不进入备份

## 运行

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

开发期可通过 `lib/dev/mock_seeder.dart` 注入样例数据：

- 默认幂等：检测到库内已有数据时会直接返回 `SeedResult.alreadySeeded()`（`skipped=true`），不会写入重复记录
- 如需强制重新写入，调用 `seedMockData(ref, force: true)`（或在设置页确认对话框里选"强制注入"）
- UI 入口：仪表盘右上角「注入示例数据」快捷按钮，以及 `设置 → 开发者` 区域

## 本地测试环境

当前开发基线机器与设备配置：

- **OS**：macOS 15.3.1（Sequoia, build 24D70）
- **Flutter**：3.41.7 • stable • Dart 3.11.5 • DevTools 2.54.2
- **Android SDK**：`~/Library/Android/sdk`（`platform-tools/adb`、`emulator/emulator`）
- **Android 模拟器 AVD**：`gwp_avd`
- **iOS 工具链**：当前机器仅装 Command Line Tools；如需真机 / 模拟器调试，请安装完整 Xcode 并 `sudo xcode-select -s /Applications/Xcode.app`
- **Android 配置**：`compileSdk / minSdk / targetSdk / ndkVersion` 均跟随 Flutter 工具链默认值（见 `android/app/build.gradle.kts`）

### 标准构建 → 安装 → 验证链（Android 调试）

任何 UI / schema / 迁移改动必须完整跑完下列步骤：

```bash
# -- 通用 --
flutter analyze                                        # 0 issues
flutter test                                           # 全部 pass（当前基线 253/253）
flutter build apk --debug                              # 产出 build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release                            # 产出 build/app/outputs/flutter-apk/app-release.apk

# -- macOS --
~/Library/Android/sdk/platform-tools/adb install -r \
  build/app/outputs/flutter-apk/app-debug.apk          # 返回 Success 才算收尾

# -- Windows WSL2 --
env -u ADB_SERVER_SOCKET ADB_MDNS=0 $ANDROID_HOME/platform-tools/adb install -r \
  build/app/outputs/flutter-apk/app-debug.apk          # 返回 Success 才算收尾
```

若 `adb` 不在 PATH，请直接用上面的绝对路径。启动模拟器：

```bash
# macOS
~/Library/Android/sdk/emulator/emulator -avd gwp_avd

# Windows WSL2（必须用 x86_64 镜像）
nohup $ANDROID_HOME/emulator/emulator -avd gwp_avd -port 5554 -no-boot-anim &
```

### Android 模拟器 / AVD 配置

当前基线机器使用的 AVD（`~/.android/avd/gwp_avd.avd/config.ini` 摘要）：

| 项 | 值 |
| --- | --- |
| AVD 名称 | `gwp_avd` |
| 设备 | Google Pixel 6 |
| 系统镜像 | `system-images/android-34/google_apis/arm64-v8a` |
| API Level | 34（Android 14） |
| ABI | arm64-v8a（Apple Silicon 原生，速度最佳） |
| 内存 | 1536 MB |
| 模拟器版本 | 36.5.10.0 |

#### 新机器创建同款 AVD

```bash
# 0. 先确认 sdkmanager / avdmanager 可用
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

# 1. 安装必备组件（首次）
sdkmanager --install \
  "platform-tools" \
  "emulator" \
  "platforms;android-34" \
  "system-images;android-34;google_apis;arm64-v8a"

# 2. 接受 license
yes | sdkmanager --licenses

# 3. 创建 AVD（Pixel 6 / API 34 / arm64）
echo "no" | avdmanager create avd \
  -n gwp_avd \
  -k "system-images;android-34;google_apis;arm64-v8a" \
  -d "pixel_6"

# 4. 列出确认
avdmanager list avd | grep gwp_avd

# 5. 启动
emulator -avd gwp_avd &
```

> **Intel Mac**：把两个 `arm64-v8a` 改成 `x86_64`。
>
> **希望更大内存 / 存储**：创建后可直接编辑 `~/.android/avd/gwp_avd.avd/config.ini`：
> - `hw.ramSize = 3072`（MB）
> - `disk.dataPartition.size = 6G`
> - `vm.heapSize = 512`（MB）

#### 其他常用命令

```bash
avdmanager list avd                              # 列出全部 AVD
avdmanager list device                           # 列出可用设备模板
avdmanager delete avd -n gwp_avd                 # 删除
emulator -list-avds                              # 仅看 AVD 名称
emulator -avd gwp_avd -wipe-data                 # 重置用户分区（解决首启异常）
emulator -avd gwp_avd -no-snapshot-load          # 冷启动，不从快照恢复
emulator -avd gwp_avd -gpu host                  # 强制宿主 GPU
```

### macOS 一键从 0 到调试（完整流程）

首次 clone / 迁移新机后，按顺序执行即可把 Android 调试跑起来：

```bash
# 0. 环境自检（红叉的部分按提示补）
flutter doctor -v

# 1. 拉依赖
flutter pub get

# 2. 生成 freezed / drift / json 代码
dart run build_runner build --delete-conflicting-outputs

# 3. 静态检查 + 测试（必须全绿）
flutter analyze
flutter test

# 4. 启动 Android 模拟器（后台，AVD 名称按本机 avdmanager list avd 确认）
~/Library/Android/sdk/emulator/emulator -avd gwp_avd -netdelay none -netspeed full &
# 等模拟器 boot 完成（sys.boot_completed=1）
~/Library/Android/sdk/platform-tools/adb wait-for-device shell \
  'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done;'

# 5. 确认设备在线
~/Library/Android/sdk/platform-tools/adb devices -l
flutter devices

# 6A. 开发热重载模式（推荐日常开发；Dart VM 保持连接，按 r=热重载, R=热重启, q=退出）
flutter run -d emulator-5554

# 6B. 或者走「构建 APK → 安装」的发布式调试（更贴近用户真实安装包）
flutter build apk --debug
~/Library/Android/sdk/platform-tools/adb install -r \
  build/app/outputs/flutter-apk/app-debug.apk
~/Library/Android/sdk/platform-tools/adb shell am start \
  -n com.example.gwp/.MainActivity     # 包名以 android/app/build.gradle.kts 为准

# 7. 实时日志（只看 Flutter 相关）
~/Library/Android/sdk/platform-tools/adb logcat -v time flutter:V '*:S'

# 8. DevTools（性能 / Widget Inspector / 网络）
dart devtools
# 按提示打开浏览器，并把 flutter run 输出的 VM Service URI 贴进去
```

### 常见卡点与兜底

- **`adb: command not found`** → 用绝对路径 `$ANDROID_HOME/platform-tools/adb`（macOS: `~/Library/Android/sdk/platform-tools/adb`），或将其加入 shell 配置的 PATH
- **WSL2 `adb` 挂起 / 超时** → 最常见原因是 `ADB_SERVER_SOCKET` 环境变量指向无效端口（如 `tcp:0.0.0.0:15555`）。每个 adb 命令前加 `env -u ADB_SERVER_SOCKET ADB_MDNS=0`；若仍失效则 `killall -9 adb` 后重试
- **`flutter test` 报 `HandshakeException`** → sqlite3 包默认从 GitHub 下载预编译 SQLite 库失败。需手动下载 `libsqlite3mc.x64.linux.so` 到 `.dart_tool/hooks_runner/shared/sqlite3/build/download-4484332/`，SHA256 校验通过后重跑
- **`flutter build apk --release` 卡住** → 同上，Android 构建还需要 arm64/arm/x64 版本的 `libsqlite3mc.so`，若下载失败需同理手动处理
- **模拟器启动后黑屏 / 卡 launcher** → `emulator -avd gwp_avd -wipe-data` 重置用户分区
- **build_runner 冲突** → 永远加 `--delete-conflicting-outputs`
- **Gradle 首次构建很慢 / 被墙** → 在 `~/.gradle/init.d/` 配镜像；或 `android/gradle.properties` 加 `org.gradle.jvmargs=-Xmx4g`；Gradle daemon 卡住时用 `./gradlew assembleDebug --no-daemon` 观察实时进度
- **安装失败 `INSTALL_FAILED_UPDATE_INCOMPATIBLE`** → 签名/包名变了，先 `adb uninstall com.gwp.gwp`
- **Drift schema 变更后首启崩溃** → 检查 `onUpgrade` 是否覆盖当前 `from`；开发期可 `adb shell pm clear com.gwp.gwp` 清数据重来
- **真机调试** → 手机开「开发者选项 → USB 调试」，`adb devices` 看到后 `flutter run -d <serial>`
- **iOS 调试** → 需要完整 Xcode：`sudo xcode-select -s /Applications/Xcode.app`；然后 `cd ios && pod install && cd ..` → `open ios/Runner.xcworkspace` 选签名账号 → `flutter run -d <iPhone>`

### Windows WSL2 一键从 0 到调试（完整流程）

首次 clone / 新机搭建时，按顺序执行即可：

```bash
# 0. 环境自检
flutter doctor -v

# 1. 拉依赖
flutter pub get

# 2. 生成 freezed / drift / json 代码
dart run build_runner build --delete-conflicting-outputs

# 3. 静态检查 + 测试（必须全绿）
flutter analyze
flutter test

# 4. 创建 AVD（首次，API 34 / x86_64，WSL2 必须用 x86_64 镜像）
sdkmanager --install \
  "platform-tools" \
  "emulator" \
  "platforms;android-34" \
  "system-images;android-34;google_apis;x86_64"
echo "no" | avdmanager create avd \
  -n gwp_avd \
  -k "system-images;android-34;google_apis;x86_64" \
  -d "pixel_6"

# 5. 启动模拟器（后台，指定端口 5554）
nohup $ANDROID_HOME/emulator/emulator -avd gwp_avd -port 5554 \
  -no-boot-anim -no-snapshot-load > /tmp/emulator.log 2>&1 &

# 6. 等待模拟器 boot 完成
# --- 关键：WSL2 中 adb 可能因 ADB_SERVER_SOCKET 环境变量指向无效端口而超时 ---
# 先检查是否有问题变量：
echo "$ADB_SERVER_SOCKET"
# 若有输出（如 tcp:0.0.0.0:15555），后续每个 adb 命令必须 unset：
unset ADB_SERVER_SOCKET
ADB_MDNS=0 adb wait-for-device shell \
  'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done;'

# 7. 确认设备在线
unset ADB_SERVER_SOCKET && ADB_MDNS=0 adb devices -l

# 8A. 开发热重载模式
flutter run -d emulator-5554

# 8B. 构建 APK → 安装（发布式调试）
flutter build apk --debug
flutter build apk --release   # 首次会下载 SQLite3MultipleCiphers 原生二进制
unset ADB_SERVER_SOCKET && ADB_MDNS=0 adb install -r \
  build/app/outputs/flutter-apk/app-debug.apk
unset ADB_SERVER_SOCKET && ADB_MDNS=0 adb shell am start \
  -n com.gwp.gwp/.MainActivity

# 9. 实时日志
unset ADB_SERVER_SOCKET && ADB_MDNS=0 adb logcat -v time flutter:V '*:S'
```

#### WSL2 特有卡点与兜底

- **`adb` 命令挂起 / 超时**：最常见原因是 `ADB_SERVER_SOCKET` 环境变量指向了无效端口（如 `tcp:0.0.0.0:15555`）。执行 `unset ADB_SERVER_SOCKET && ADB_MDNS=0 adb devices` 验证是否能正常列出设备。如果恢复，建议在 `~/.bashrc` 中移除或修正该变量。
- **SQLite3MultipleCiphers 原生库下载失败（`HandshakeException`）**：`flutter test` 和 `flutter build apk --release` 会从 GitHub 下载预编译的 `libsqlite3mc.*.so`。若网络不通（常见于境内 / 无代理环境），需手动下载并放入缓存目录：

  ```bash
  # 1. 确定需要的文件和目标位置（以 Linux x64 测试 / Android arm64 构建为例）
  # Linux x64（flutter test 用）
  DST_DIR="$PROJECT/.dart_tool/hooks_runner/shared/sqlite3/build/download-4484332"
  # 如果不存在，先用 flutter test 触发一次，观察 stderr 中的目标目录后替换

  # 2. 手动下载（需要 GitHub 可达的网络环境，或从其他机器拷贝）
  BASE_URL="https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.3.1"
  curl -L -o "$DST_DIR/libsqlite3mc.so" "$BASE_URL/libsqlite3mc.x64.linux.so"

  # 3. 校验 SHA256（必须匹配，否则 hook 会拒绝使用）
  echo "9139316c6bffee12ea095c5353fa2a10362aa3698cf04cf12ffcf982e248dc1a  $DST_DIR/libsqlite3mc.so" | sha256sum -c

  # 4. 清理残留的 0 字节 .tmp 文件
  rm -f "$DST_DIR/libsqlite3mc.so.tmp"
  ```

  **提示**：Android 构建时 hook 会自动为 arm64/arm/x64 分别下载对应 `.so`，如果 Android 构建也卡住，同理需手动下载 Android ABI 版本的 `libsqlite3mc.{arch}.android.so` 到 Gradle 对应的 jniLibs 目录。
- **Gradle daemon 卡住**：首次构建 Gradle 会下载大量依赖（含 Android SDK Platform 35、NDK 28 等），可能耗时 10 分钟以上。建议直接用 `./gradlew assembleDebug --no-daemon` 观察实时进度，避免 daemon 在后台静默失败。
- **Gradle 构建很慢**：在 `~/.gradle/init.d/` 配置国内镜像源；或在 `android/gradle.properties` 中增加 JVM 堆内存 `org.gradle.jvmargs=-Xmx4g`。
- **模拟器必须用 x86_64 镜像**：WSL2 不支持 arm64-v8a 模拟器镜像，创建 AVD 时务必选择 `system-images;android-34;google_apis;x86_64`。
- **模拟器启动后黑屏**：`emulator -avd gwp_avd -wipe-data` 重置用户分区。
- **安装失败 `INSTALL_FAILED_UPDATE_INCOMPATIBLE`**：签名/包名变了，先 `adb uninstall com.gwp.gwp`。
- **Drift schema 变更后首启崩溃**：检查 `onUpgrade` 是否覆盖当前 `from` 区间；开发期可 `adb shell pm clear com.gwp.gwp` 清数据重来。

## 测试

```bash
flutter analyze
flutter test
```

当前基线：**518 tests passed**，`flutter analyze` 0 issue。

覆盖：
- Drift in-memory 集成测试（Account / Asset / Card / Channel / Event CRUD）
- Card update 部分字段保留原密文 + 卡号替换时重新加密
- 加密往返（密文不含明文、错误密钥失败、HKDF 派生一致性/独立性）
- 金额 Decimal 往返与按币种格式化
- 领域校验（quantity 负数、account 不存在等）
- 卡号 / CVV 解密路径
- Channel 规则引擎 + PlanTransferRoute（minFee / minHops / violations）
- AggregateAccountValue（多币种跨汇率、缺汇率 → missingRates）
- Event 幂等（sourceKey 去重）+ Ack 流程 + watchPending/Recent

## 代码生成

修改 Drift 表 / Freezed 实体后执行：

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 安全约定

- 卡号、CVV 仅以 AES-GCM 密文（Base64）入库，明文只存在于创建瞬间与「查看真实卡号」的临时内存
- 主密钥在平台 Keystore（Android）/ Keychain（iOS, `first_unlock_this_device`）
- 子密钥按 `purpose` 派生：`field.card_no` / `field.cvv` / `backup.payload` / `db.sqlcipher`
- Release 构建需关闭 `debugPrint`；敏感字段永远不进日志
- 外部行情请求仅发送 symbol / currency 代码，绝不携带账户或持仓信息

## 实施进度（对齐 `doc/architecture.md` §9）

- [x] 1. 工程初始化 + Drift 6 张表 + migration
- [x] 2. core/crypto + core/money + Result
- [x] 3. Account / Card / Asset 三个 feature 的 CRUD 与列表
- [x] 4. ExchangeRate 导入 + PriceProvider 抽象（Frankfurter）
- [x] 5. Asset 估值 UseCase + 事件总线 + Event 持久化
- [x] 6. Channel 规则引擎 + 转账模拟
- [x] 7. 生物识别、备份导入导出
- [x] 8. 外部资产行情（Yahoo Finance）+ 统一同步按钮 + 缓存覆盖提示
- [x] 9. 统一搜索（AppBar + 预设过滤 Chip + 实时结果）
- [x] 10. 全量实体 CRUD 闭环（编辑路由 + 软/硬删除 + 卡片部分字段更新重加密）
- [x] 11. 仪表盘深度优化（多维度 KPI / 趋势 delta 区间切换 / 信用账单提醒 / 活动 feed / 今日汇率提醒横幅）
- [x] 12. 体验与可维护性补齐：事件中心快捷操作、本地通知、资产成本历史审计
- [x] 13. 分层/精度/安全整固：Provider 抽象移入 `domain/`（AssetPriceProvider / FxRateProvider / pairKeyOf）；WatchedPair 阈值 `REAL → TEXT(Decimal)`（schema v12）；仪表盘累加全程 Decimal；备份不直接携带设备绑定密文，卡号走可迁移恢复、CVV 继续排除
- [ ] 14. UI 打磨：主题完善、空 / 错误态细化、国际化
