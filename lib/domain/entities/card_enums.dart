import '../../core/errors.dart';

enum CardType {
  debit('DEBIT'),
  credit('CREDIT'),
  prepaid('PREPAID');

  const CardType(this.code);
  final String code;

  static CardType fromCode(String code) => CardType.values.firstWhere(
        (e) => e.code == code,
        orElse: () => throw StorageError('unknown CardType: $code'),
      );
}

enum CardStatus {
  active('ACTIVE'),
  locked('LOCKED'),
  expired('EXPIRED'),
  closed('CLOSED');

  const CardStatus(this.code);
  final String code;

  static CardStatus fromCode(String code) => CardStatus.values.firstWhere(
        (e) => e.code == code,
        orElse: () => throw StorageError('unknown CardStatus: $code'),
      );
}

/// 发卡组织固定枚举。
///
/// 用「固定集合」而非字典表，因为：
/// 1) 全球主流发卡组织近十年都是这几家，不存在用户自定义扩展的正当需求；
/// 2) 日后要对接卡 BIN 归类、消费场景标签时，我们需要**稳定的枚举**而不是
///    用户随手填写的字符串（'銀聯' / 'UnionPay' / 'CUP' 会让后续统计崩溃）。
///
/// DB 存储 `.code`（大写），UI 通过 [labelZh] 渲染。历史自由填入的值会在
/// Card 创建表单里通过 [CardOrganization.tryFromCode] 兜底为 null，UI 渲染
/// 时显示为「未指定」并强制在编辑保存时选一个。
enum CardOrganization {
  visa('VISA'),
  mastercard('MASTERCARD'),
  unionpay('UNIONPAY'),
  jcb('JCB'),
  amex('AMEX'),
  discover('DISCOVER'),
  diners('DINERS');

  const CardOrganization(this.code);
  final String code;

  static CardOrganization fromCode(String code) => CardOrganization.values.firstWhere(
        (e) => e.code == code,
        orElse: () => throw StorageError('unknown CardOrganization: $code'),
      );

  /// 容忍历史自由文本：未命中枚举时返回 null，由调用方决定降级策略。
  static CardOrganization? tryFromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final e in CardOrganization.values) {
      if (e.code == code) return e;
    }
    return null;
  }
}
