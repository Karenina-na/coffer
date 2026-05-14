import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/crypto/password_kdf.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/core/result.dart';
import 'package:gwp/data/backup/db_snapshot.dart';
import 'package:gwp/data/crypto_service.dart';
import 'package:gwp/data/db/database.dart';
import 'package:gwp/data/repositories/drift_account_repository.dart';
import 'package:gwp/domain/entities/account_enums.dart';
import 'package:gwp/domain/usecases/backup_restore.dart';
import 'package:gwp/domain/usecases/create_account.dart';

void main() {
  late AppDatabase db;
  late DbSnapshotService snapshot;
  late CryptoService crypto;

  // 降低 Argon2id 档位，避免测试过慢。
  final fastKdf = PasswordKdf(memoryKib: 4096, iterations: 2, parallelism: 1);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    crypto = _FakeCryptoService();
    snapshot = DbSnapshotService(db, crypto);
    final repo = DriftAccountRepository(db.accountDao);
    final createAccount = CreateAccountUseCase(
      repo,
      idGenerator: () => 'acc-backup',
      now: () => DateTime.utc(2024, 1, 1),
    );
    final r = await createAccount(
      accountType: AccountType.bank,
      sovereigntyRegion: 'CN',
      institutionName: 'ICBC',
    );
    expect(r.isOk, true);
  });

  tearDown(() => db.close());

  test('export → import round-trip 恢复原数据', () async {
    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'p@ssword-1');
    expect(packed.isOk, true);

    // 清空 DB 后再 import
    await db.delete(db.accounts).go();
    expect(await db.select(db.accounts).get(), isEmpty);

    final importer = ImportBackupUseCase(snapshot);
    final restored = await importer(
      package: packed.valueOrNull!,
      password: 'p@ssword-1',
    );
    expect(restored.isOk, true);

    final rows = await db.select(db.accounts).get();
    expect(rows.length, 1);
    expect(rows.single.id, 'acc-backup');
    expect(rows.single.institutionName, 'ICBC');
  });

  test('错误口令解密失败', () async {
    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'correct-pass');
    expect(packed.isOk, true);

    final importer = ImportBackupUseCase(snapshot);
    final r = await importer(
      package: packed.valueOrNull!,
      password: 'wrong-pass',
    );
    expect(r.isErr, true);
  });

  test('导出拒绝过短口令', () async {
    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'short');
    expect(packed.isErr, true);
    expect(
      packed.errorOrNull?.message,
      contains('password too short for backup encryption'),
    );
  });

  test('导入拒绝过短口令', () async {
    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'correct-pass');
    expect(packed.isOk, true);

    final importer = ImportBackupUseCase(snapshot);
    final r = await importer(package: packed.valueOrNull!, password: 'short');
    expect(r.isErr, true);
    expect(
      r.errorOrNull?.message,
      contains('password too short for backup encryption'),
    );
  });

  test('v2 导出绑定 AAD：篡改 kdf.params.t 后解密失败', () async {
    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'password-ok');
    expect(packed.isOk, true);

    final pack = jsonDecode(packed.valueOrNull!) as Map<String, dynamic>;
    expect(pack['version'], 2);

    // 把迭代次数 t 篡改为 1，模拟攻击者降低 KDF 强度。
    (pack['kdf']['params'] as Map)['t'] = 1;
    final tampered = jsonEncode(pack);

    final importer = ImportBackupUseCase(snapshot);
    final r = await importer(package: tampered, password: 'password-ok');
    expect(r.isErr, true, reason: 'AAD 绑定必须让 kdf 元数据的任何篡改立刻导致 MAC 失败');
  });

  test('篡改 salt 也会让解密失败（AAD 覆盖 salt）', () async {
    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'password-ok');
    final pack = jsonDecode(packed.valueOrNull!) as Map<String, dynamic>;
    // 把 salt 改成同长度但不同内容的 base64（AAAAAAA...）
    pack['kdf']['salt'] = base64Encode(List<int>.filled(16, 0));
    final tampered = jsonEncode(pack);
    final importer = ImportBackupUseCase(snapshot);
    final r = await importer(package: tampered, password: 'password-ok');
    expect(r.isErr, true);
  });

  test('导入拒绝超出 backupMaxBytes 的包', () async {
    final importer = ImportBackupUseCase(snapshot);
    final huge = 'x' * (backupMaxBytes + 1);
    final r = await importer(package: huge, password: 'x');
    expect(r.isErr, true);
  });

  test('导入拒绝空包', () async {
    final importer = ImportBackupUseCase(snapshot);
    final r = await importer(package: '', password: 'x');
    expect(r.isErr, true);
  });

  test('未来未知版本被拒绝', () async {
    final importer = ImportBackupUseCase(snapshot);
    final fake = jsonEncode({
      'version': 999,
      'kdf': {'algo': 'argon2id'},
      'cipher': {'algo': 'aes-gcm-256'},
    });
    final r = await importer(package: fake, password: 'x');
    expect(r.isErr, true);
  });

  test('卡号以可迁移明文进入快照，CVV 不进入快照', () async {
    final cardNoCt = await crypto.encryptField(
      purpose: CryptoPurpose.cardNo,
      plaintext: '4111111111111234',
    );
    final cvvCt = await crypto.encryptField(
      purpose: CryptoPurpose.cvv,
      plaintext: '123',
    );
    expect(cardNoCt.isOk, isTrue);
    expect(cvvCt.isOk, isTrue);

    await db.into(db.cards).insert(
      CardsCompanion.insert(
        id: 'c-1',
        accountId: 'acc-backup',
        cardOrganization: 'VISA',
        cardNoMasked: '**** **** **** 1234',
        cardType: 'credit',
        expireMonth: 12,
        expireYear: 2030,
        issuerName: 'ICBC',
        status: 'active',
        cardNoCiphertext: Value(cardNoCt.valueOrNull!),
        cvvCiphertext: Value(cvvCt.valueOrNull!),
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 1),
      ),
    );

    final snap = await snapshot.export();
    final cards = snap['cards']!;
    expect(cards, hasLength(1));
    expect(cards.single['cardNoBackup'], '4111111111111234');
    expect(cards.single.containsKey('cardNoCiphertext'), isFalse);
    expect(cards.single.containsKey('cvvCiphertext'), isFalse);
    expect(cards.single['id'], 'c-1');
  });

  test('导入后会重新加密卡号，CVV 保持为空', () async {
    final snap = <String, List<Map<String, dynamic>>>{
      'accounts': [
        {
          'id': 'acc-backup',
          'accountType': 'bank',
          'sovereigntyRegion': 'CN',
          'institutionName': 'ICBC',
          'status': 'active',
          'fxSpreadPercent': 0.0,
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-01T00:00:00.000Z',
          'isDeleted': false,
        },
      ],
      'assets': const [],
      'asset_cost_history': const [],
      'cards': [
        {
          'id': 'c-restore',
          'accountId': 'acc-backup',
          'cardOrganization': 'VISA',
          'cardNoMasked': '**** **** **** 1234',
          'cardType': 'credit',
          'expireMonth': 12,
          'expireYear': 2030,
          'issuerName': 'ICBC',
          'supportsAllCurrencies': false,
          'isVirtual': false,
          'status': 'active',
          'sortOrder': 1000,
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-01T00:00:00.000Z',
          'cardNoBackup': '4111111111111234',
        },
      ],
      'channels': const [],
      'dict_entries': const [],
      'account_channels': const [],
      'exchange_rates': const [],
      'events': const [],
      'asset_price_history': const [],
      'watched_pairs': const [],
      'search_history_entries': const [],
    };

    await snapshot.restore(snap);
    final row = await (db.select(db.cards)..where((t) => t.id.equals('c-restore'))).getSingle();
    expect(row.cardNoCiphertext != null, isTrue);
    expect(row.cvvCiphertext == null, isTrue);

    final decrypted = await crypto.decryptField(
      purpose: CryptoPurpose.cardNo,
      ciphertext: row.cardNoCiphertext!,
    );
    expect(decrypted.isOk, isTrue);
    expect(decrypted.valueOrNull, '4111111111111234');
  });

  test('inspect backup 返回摘要', () async {
    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'inspect-pass-1');
    expect(packed.isOk, isTrue);

    final inspect = InspectBackupUseCase(snapshot);
    final preview = await inspect(
      package: packed.valueOrNull!,
      password: 'inspect-pass-1',
    );
    expect(preview.isOk, isTrue);
    expect(preview.valueOrNull!.version, backupFormatVersion);
    expect(preview.valueOrNull!.tableCounts['accounts'], 1);
  });

  test('v1 备份包被拒绝（Bug 10：KDF 降级攻击防护）', () async {
    // 手工构造一个 version=1 的包，模拟旧版或被降级的包
    final fakeV1 = jsonEncode({
      'version': 1,
      'kdf': {
        'algo': 'argon2id',
        'salt': 'AAAAAAAAAAAAAAAA',
        'params': {'m': 65536, 't': 3, 'p': 1},
      },
      'cipher': {
        'algo': 'aes-gcm-256',
        'nonce': 'AAAAAAAAAAAA',
        'ciphertext': 'AAAA',
      },
    });
    final importer = ImportBackupUseCase(snapshot);
    final r = await importer(package: fakeV1, password: 'any-password');
    expect(r.isErr, isTrue, reason: 'v1 包必须被拒绝');
  });

  test('export 快照包含 3 张之前缺失的表（Bug 14）', () async {
    final snap = await snapshot.export();
    expect(snap.containsKey('asset_cost_history'), isTrue,
        reason: 'asset_cost_history 必须在快照中');
    expect(snap.containsKey('account_channels'), isTrue,
        reason: 'account_channels 必须在快照中');
    expect(snap.containsKey('watched_pairs'), isTrue,
        reason: 'watched_pairs 必须在快照中');
    expect(snap.containsKey('search_history_entries'), isTrue,
        reason: 'search_history_entries 必须在快照中');
    expect(snap.containsKey('dict_entries'), isTrue,
        reason: 'dict_entries 必须在快照中');
  });

  test('exportJson 与 export 语义一致', () async {
    final snap = await snapshot.export();
    final text = await snapshot.exportJson();
    final decoded = (jsonDecode(text) as Map).cast<String, dynamic>().map(
      (k, v) => MapEntry(
        k,
        (v as List).map((e) => (e as Map).cast<String, dynamic>()).toList(),
      ),
    );
    expect(decoded, snap);
  });

  test('含 3 张缺失表的完整往返（Bug 14）', () async {
    // 向 watched_pairs 插入一条记录
    await db.customStatement(
      "INSERT INTO watched_pairs "
      "(pair_key, base_currency, quote_currency, created_at) "
      "VALUES ('USD/CNY', 'USD', 'CNY', 1749988800)",
    );

    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'test-pass-123');
    expect(packed.isOk, isTrue);

    // 清空所有表
    await db.delete(db.watchedPairs).go();
    await db.delete(db.accounts).go();
    expect(await db.select(db.watchedPairs).get(), isEmpty);

    final importer = ImportBackupUseCase(snapshot);
    final r = await importer(
      package: packed.valueOrNull!,
      password: 'test-pass-123',
    );
    expect(r.isOk, isTrue);

    // watched_pairs 应该被恢复
    final pairs = await db.select(db.watchedPairs).get();
    expect(pairs, hasLength(1));
    expect(pairs.single.pairKey, 'USD/CNY');
  });

  test('restore 会清空旧的 search_history_entries', () async {
    await db.customStatement(
      "INSERT INTO search_history_entries "
      "(kind, unique_key, query, visited_at, updated_at) "
      "VALUES ('QUERY', 'Q:legacy', 'legacy', 1749988800, 1749988800)",
    );

    final snap = await snapshot.export();
    snap['search_history_entries'] = const [];

    await snapshot.restore(snap);

    final rows = await db.select(db.searchHistoryEntries).get();
    expect(rows, isEmpty);
  });

  test('restore preserves dict_entries', () async {
    await db.customStatement(
      "INSERT INTO dict_entries "
      "(type, code, name, sort_order, is_builtin, created_at, updated_at) "
      "VALUES ('CURRENCY', 'ZZZ', '测试币种', 999, 0, 1749988800, 1749988800)",
    );

    final snap = await snapshot.export();

    await db.delete(db.dictEntries).go();
    await snapshot.restore(snap);

    final dicts = await db.select(db.dictEntries).get();
    expect(dicts.where((e) => e.code == 'ZZZ'), isNotEmpty);
  });

  // ── DEFECT-1 修复验证：恶意备份包 KDF 参数范围校验 ──────────────────────

  test('恶意备份包 memoryKib 极大值被拒绝（OOM 防护）', () async {
    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'valid-password-1');
    expect(packed.isOk, isTrue);

    // 构造恶意包：把 memoryKib 替换为极大值
    final pack = jsonDecode(packed.valueOrNull!) as Map<String, dynamic>;
    (pack['kdf']['params'] as Map)['m'] = 2147483647; // 约 2TB
    final malicious = jsonEncode(pack);

    final importer = ImportBackupUseCase(snapshot);
    final r = await importer(package: malicious, password: 'valid-password-1');
    expect(r.isErr, isTrue, reason: '超限 memoryKib 必须被拒绝');
    expect(
      r.errorOrNull?.message,
      contains('invalid kdf params'),
    );
  });

  test('恶意备份包 iterations 超限被拒绝', () async {
    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'valid-password-2');
    expect(packed.isOk, isTrue);

    final pack = jsonDecode(packed.valueOrNull!) as Map<String, dynamic>;
    (pack['kdf']['params'] as Map)['t'] = 9999;
    final malicious = jsonEncode(pack);

    final importer = ImportBackupUseCase(snapshot);
    final r = await importer(package: malicious, password: 'valid-password-2');
    expect(r.isErr, isTrue, reason: '超限 iterations 必须被拒绝');
    expect(r.errorOrNull?.message, contains('invalid kdf params'));
  });

  test('恶意备份包 kdf params 类型错误（String 而非 int）被拒绝', () async {
    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'valid-password-3');
    expect(packed.isOk, isTrue);

    final pack = jsonDecode(packed.valueOrNull!) as Map<String, dynamic>;
    (pack['kdf']['params'] as Map)['m'] = 'huge'; // 字符串类型
    final malicious = jsonEncode(pack);

    final importer = ImportBackupUseCase(snapshot);
    final r = await importer(package: malicious, password: 'valid-password-3');
    expect(r.isErr, isTrue, reason: '非 int 类型 kdf params 必须被拒绝');
    expect(r.errorOrNull?.message, contains('invalid kdf params'));
  });

  test('合法 kdf params 不被范围检查拒绝（正常导入仍可用）', () async {
    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'valid-password-4');
    expect(packed.isOk, isTrue);

    await db.delete(db.accounts).go();

    final importer = ImportBackupUseCase(snapshot);
    final r = await importer(
      package: packed.valueOrNull!,
      password: 'valid-password-4',
    );
    expect(r.isOk, isTrue, reason: '合法备份包应正常导入');
  });
}

class _FakeCryptoService extends CryptoService {
  _FakeCryptoService();

  final Map<String, String> _cipherToPlain = {};

  @override
  Future<Result<String, AppError>> encryptField({
    required String purpose,
    required String plaintext,
  }) async {
    final ciphertext = 'ct::$purpose::$plaintext';
    _cipherToPlain[ciphertext] = plaintext;
    return Ok(ciphertext);
  }

  @override
  Future<Result<String, AppError>> decryptField({
    required String purpose,
    required String ciphertext,
  }) async {
    final plaintext = _cipherToPlain[ciphertext];
    if (plaintext == null) {
      return const Err(CryptoError('fake decrypt failed'));
    }
    return Ok(plaintext);
  }
}
