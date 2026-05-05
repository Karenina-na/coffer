import '../../core/errors.dart';
import 'account_enums.dart';

enum ChannelStatus {
  enabled('ENABLED'),
  disabled('DISABLED'),
  maintenance('MAINTENANCE');

  const ChannelStatus(this.code);
  final String code;

  static ChannelStatus fromCode(String code) => ChannelStatus.values.firstWhere(
        (e) => e.code == code,
        orElse: () => throw StorageError('unknown ChannelStatus: $code'),
      );
}

/// 账户类型别名，避免 feature 层交叉引用。
typedef AccountTypeAlias = AccountType;
