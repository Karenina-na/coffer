import '../../core/errors.dart';

/// 账户类型枚举，与 doc/data-definitions.md §1 对齐。
enum AccountType {
  bank('BANK'),
  broker('BROKER'),
  insurance('INSURANCE'),
  payment('PAYMENT'),
  custody('CUSTODY'),
  cryptoExchange('CRYPTO_EXCHANGE'),
  cryptoWallet('CRYPTO_WALLET');

  const AccountType(this.code);
  final String code;

  static AccountType fromCode(String code) => AccountType.values.firstWhere(
        (e) => e.code == code,
        orElse: () => throw StorageError('unknown AccountType: $code'),
      );
}

/// 账户生命周期状态。
enum AccountStatus {
  active('ACTIVE'),
  inactive('INACTIVE'),
  dormant('DORMANT'),
  closed('CLOSED');

  const AccountStatus(this.code);
  final String code;

  static AccountStatus fromCode(String code) => AccountStatus.values.firstWhere(
        (e) => e.code == code,
        orElse: () => throw StorageError('unknown AccountStatus: $code'),
      );
}
