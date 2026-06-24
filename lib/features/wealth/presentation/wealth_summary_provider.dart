import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/valuation/valuation_currency_provider.dart';
import '../../account/presentation/account_providers.dart';
import '../../asset/presentation/asset_providers.dart';

class WealthSummary {
  const WealthSummary({
    required this.baseCurrency,
    required this.total,
    required this.accountCount,
    required this.assetCount,
    required this.missingAssetIds,
  });

  final String baseCurrency;
  final Decimal total;
  final int accountCount;
  final int assetCount;
  final List<String> missingAssetIds;
}

final wealthSummaryProvider = FutureProvider.autoDispose<WealthSummary>((
  ref,
) async {
  final base = ref.watch(valuationCurrencyProvider);
  final accounts = await ref.watch(accountListProvider.future);
  final valued = await ref.watch(valuedAssetsProvider.future);

  return WealthSummary(
    baseCurrency: base,
    total: valued.total,
    accountCount: accounts.length,
    assetCount: valued.assets.length,
    missingAssetIds: valued.missingAssetIds,
  );
});
