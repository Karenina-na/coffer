import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/asset.dart';
import '../repositories/exchange_rate_repository.dart';

class AssetValuation {
  const AssetValuation({
    required this.asset,
    required this.valueInBase,
  });

  final Asset asset;
  final Decimal valueInBase;
}

class AccountAggregate {
  const AccountAggregate({
    required this.baseCurrency,
    required this.total,
    required this.rows,
    required this.missingRates,
  });

  final String baseCurrency;
  final Decimal total;
  final List<AssetValuation> rows;

  /// 无法折算（无汇率/无市值）的资产 id 列表；UI 可提示用户补充汇率。
  final List<String> missingRates;
}

/// 聚合账户下资产总价值到 [baseCurrency]。
///
/// 规则：
/// - 若资产 [Asset.marketValue] 为空则跳过并记入 [missingRates]
/// - 若 [Asset.currency] == [baseCurrency] 不走汇率
/// - 否则通过 [PriceProvider] 获取汇率；失败则记入 [missingRates]
class AggregateAccountValueUseCase {
  AggregateAccountValueUseCase(this._priceProvider);

  final PriceProvider _priceProvider;

  Future<Result<AccountAggregate, AppError>> call({
    required List<Asset> assets,
    required String baseCurrency,
  }) async {
    if (baseCurrency.trim().isEmpty) {
      return const Err(ValidationError('本位币不能为空'));
    }
    final base = baseCurrency.trim().toUpperCase();
    final rows = <AssetValuation>[];
    final missing = <String>[];
    var total = Decimal.zero;

    for (final a in assets) {
      final mv = a.marketValue;
      if (mv == null) {
        missing.add(a.id);
        continue;
      }
      if (a.currency.toUpperCase() == base) {
        rows.add(AssetValuation(asset: a, valueInBase: mv));
        total += mv;
        continue;
      }
      final r = await _priceProvider.getRate(
        baseCurrency: a.currency,
        quoteCurrency: base,
      );
      if (r.isErr) {
        missing.add(a.id);
        continue;
      }
      final rate = r.valueOrNull!;
      if (rate <= Decimal.zero) {
        missing.add(a.id);
        continue;
      }
      final inBase = mv * rate;
      rows.add(AssetValuation(asset: a, valueInBase: inBase));
      total += inBase;
    }

    return Ok(AccountAggregate(
      baseCurrency: base,
      total: total,
      rows: rows,
      missingRates: missing,
    ));
  }
}
