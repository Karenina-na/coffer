import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/errors.dart';
import 'package:coffer/data/db/database.dart';
import 'package:coffer/data/repositories/drift_account_repository.dart';
import 'package:coffer/data/repositories/drift_asset_repository.dart';
import 'package:coffer/domain/entities/account_enums.dart';
import 'package:coffer/domain/entities/asset_enums.dart';
import 'package:coffer/domain/usecases/create_account.dart';
import 'package:coffer/domain/usecases/create_asset.dart';

/// CreateX 用例的校验路径（非 happy path）。
///
/// 这些路径此前仅被间接 / 快乐路径覆盖，补上确保参数验证不被
/// 后续重构意外削弱。
void main() {
  late AppDatabase db;
  late DriftAccountRepository accounts;
  late DriftAssetRepository assets;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accounts = DriftAccountRepository(db.accountDao);
    assets = DriftAssetRepository(db.assetDao);
  });

  tearDown(() async {
    await db.close();
  });

  DateTime fixedNow() => DateTime.utc(2026, 4, 26);
  var seq = 0;
  String nextId() => 'id-${seq++}';

  group('CreateAccountUseCase 校验', () {
    test('sovereigntyRegion 为空 → ValidationError', () async {
      final uc = CreateAccountUseCase(
        accounts,
        idGenerator: nextId,
        now: fixedNow,
      );
      final r = await uc(
        accountType: AccountType.bank,
        sovereigntyRegion: '   ',
        institutionName: 'ICBC',
      );
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<ValidationError>());
    });

    test('institutionName 为空 → ValidationError', () async {
      final uc = CreateAccountUseCase(
        accounts,
        idGenerator: nextId,
        now: fixedNow,
      );
      final r = await uc(
        accountType: AccountType.bank,
        sovereigntyRegion: 'CN',
        institutionName: '',
      );
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<ValidationError>());
    });

    test('成功路径 trim 字段并写库', () async {
      final uc = CreateAccountUseCase(
        accounts,
        idGenerator: () => 'acc-x',
        now: fixedNow,
      );
      final r = await uc(
        accountType: AccountType.bank,
        sovereigntyRegion: '  CN  ',
        institutionName: '  ICBC  ',
      );
      expect(r.isOk, isTrue);
      final got = r.valueOrNull!;
      expect(got.sovereigntyRegion, 'CN');
      expect(got.institutionName, 'ICBC');
      expect(got.createdAt, fixedNow());
    });
  });

  group('CreateAssetUseCase 校验', () {
    Future<void> seedAccount(String id) async {
      final uc = CreateAccountUseCase(
        accounts,
        idGenerator: () => id,
        now: fixedNow,
      );
      await uc(
        accountType: AccountType.broker,
        sovereigntyRegion: 'US',
        institutionName: 'IBKR',
      );
    }

    test('quantity 为负 → ValidationError', () async {
      await seedAccount('acc-1');
      final uc = CreateAssetUseCase(
        assets,
        accounts,
        idGenerator: nextId,
        now: fixedNow,
      );
      final r = await uc(
        accountId: 'acc-1',
        assetType: AssetType.stock,
        quantity: Decimal.parse('-1'),
        currency: 'USD',
      );
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<ValidationError>());
    });

    test('currency 为空 → ValidationError', () async {
      await seedAccount('acc-2');
      final uc = CreateAssetUseCase(
        assets,
        accounts,
        idGenerator: nextId,
        now: fixedNow,
      );
      final r = await uc(
        accountId: 'acc-2',
        assetType: AssetType.stock,
        quantity: Decimal.parse('1'),
        currency: '   ',
      );
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<ValidationError>());
    });

    test('costPrice 为负 → ValidationError', () async {
      await seedAccount('acc-3');
      final uc = CreateAssetUseCase(
        assets,
        accounts,
        idGenerator: nextId,
        now: fixedNow,
      );
      final r = await uc(
        accountId: 'acc-3',
        assetType: AssetType.stock,
        quantity: Decimal.parse('1'),
        currency: 'USD',
        costPrice: Decimal.parse('-0.01'),
      );
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<ValidationError>());
    });

    test('currentPrice 为负 → ValidationError', () async {
      await seedAccount('acc-4');
      final uc = CreateAssetUseCase(
        assets,
        accounts,
        idGenerator: nextId,
        now: fixedNow,
      );
      final r = await uc(
        accountId: 'acc-4',
        assetType: AssetType.stock,
        quantity: Decimal.parse('1'),
        currency: 'USD',
        currentPrice: Decimal.parse('-5'),
      );
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<ValidationError>());
    });

    test('accountId 不存在 → 冒泡仓储错误', () async {
      final uc = CreateAssetUseCase(
        assets,
        accounts,
        idGenerator: nextId,
        now: fixedNow,
      );
      final r = await uc(
        accountId: 'no-such-acc',
        assetType: AssetType.stock,
        quantity: Decimal.parse('1'),
        currency: 'USD',
      );
      expect(r.isErr, isTrue);
    });

    test('未提供 currentPrice 时 marketValue / valuationTime 均为 null',
        () async {
      await seedAccount('acc-5');
      final uc = CreateAssetUseCase(
        assets,
        accounts,
        idGenerator: () => 'ast-nomv',
        now: fixedNow,
      );
      final r = await uc(
        accountId: 'acc-5',
        assetType: AssetType.stock,
        quantity: Decimal.parse('10'),
        currency: 'USD',
      );
      expect(r.isOk, isTrue);
      final a = r.valueOrNull!;
      expect(a.marketValue, isNull);
      expect(a.valuationTime, isNull);
    });

    test('提供 currentPrice 时计算 marketValue = quantity * currentPrice',
        () async {
      await seedAccount('acc-6');
      final uc = CreateAssetUseCase(
        assets,
        accounts,
        idGenerator: () => 'ast-mv',
        now: fixedNow,
      );
      final r = await uc(
        accountId: 'acc-6',
        assetType: AssetType.stock,
        quantity: Decimal.parse('3'),
        currency: 'USD',
        currentPrice: Decimal.parse('12.5'),
      );
      expect(r.isOk, isTrue);
      final a = r.valueOrNull!;
      expect(a.marketValue, Decimal.parse('37.5'));
      expect(a.valuationTime, fixedNow());
    });
  });
}
