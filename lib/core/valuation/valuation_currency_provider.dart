import 'package:flutter_riverpod/flutter_riverpod.dart';

class ValuationCurrencyNotifier extends Notifier<String> {
  @override
  String build() => 'CNY';

  void set(String code) => state = code.trim().toUpperCase();
}

final valuationCurrencyProvider =
    NotifierProvider<ValuationCurrencyNotifier, String>(
      ValuationCurrencyNotifier.new,
    );
