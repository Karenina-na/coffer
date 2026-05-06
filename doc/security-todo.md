# 安全待办（Security TODO）

本文件登记当前仍未真正落地的安全项。每项都应包含：背景、当前状态、计划、验证手段。

---

## 1. ✅ SQLCipher 数据库加密（已完成，2026-04-25）

### 实现方案（方案 B：native asset hooks）
使用 `sqlite3` 3.x 的构建钩子切换到 **SQLite3MultipleCiphers**（drift 2.32+ 官方推荐路径，替代 EOL 的 `sqlcipher_flutter_libs`）。默认密码簇 ChaCha20-Poly1305 HMAC。

### 依赖配置
- `pubspec.yaml`:
  - `drift: ^2.32.1`
  - `sqlite3`：由 drift 传递引入（3.x）
  - **移除** `sqlcipher_flutter_libs` / `sqlite3_flutter_libs`（3.x 走 hooks 自动打包）
  - 新增根级配置：
    ```yaml
    hooks:
      user_defines:
        sqlite3:
          source: sqlite3mc
    ```

### 运行期实现
`lib/data/db/database.dart`:
1. `SecureKeyStore.loadOrCreateMaster()` 拿主密钥（平台 Keystore / Keychain）
2. `KeyDerivation.derive(purpose: 'db.sqlcipher')` 派生 32 字节子密钥（HKDF-SHA256）
3. `NativeDatabase(file, setup: ...)` 中作为第一条语句执行 `PRAGMA key = "x'<hex>'";`
4. 随后 `SELECT count(*) FROM sqlite_master` 做轻量自检，密钥错误立即抛异常
5. 首次启用时（无 `gwp.db.encrypted` 标记文件）删除旧明文 `gwp.db` + 其 WAL/SHM，落地密库后写入标记

### 验证
- [x] 独立集成测试 `test/data/sqlcipher_integration_test.dart`：
  - 写一行数据 → 落盘文件前 16 字节 **不是** 明文 "SQLite format 3" 头
  - 相同 key 重开能读出数据
  - 错误 key 抛 `SqliteException`
- [x] `flutter build apk --debug` 通过
- [x] `adb install -r` 安装并启动成功

### 字段级加密（保留）
`FieldCipher` 对卡号 / CVV 的 AES-GCM 加密继续保留，作为「数据库密钥泄漏」场景下的二次防线（depth in defense）。

### BankCard.toString() 密文泄露修复（2026-05-06）
freezed 自动生成的 `toString()` 会暴露 `cardNoCiphertext` / `cvvCiphertext` 字段。
已在 `card.dart` 源文件添加显式 `toString()` 重写掩码这些敏感字段；新增敏感字段需同步更新重写方法。

### 数据迁移说明
用户在切换前已明确表示**不保留**切换前的明文业务数据。首次启动加密版会自动清掉旧 `gwp.db`（含 WAL/SHM），用户体验等同于全新安装。
