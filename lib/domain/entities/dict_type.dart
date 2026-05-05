import '../../core/errors.dart';

/// 业务字典类型。
///
/// 用枚举而非自由字符串，是为了：
/// 1) DB 里 `dict_entries.type` 列的取值被限制在这三个代码内，不会因为
///    上层笔误写错（比如 `COUNTRY` vs `REGION`）污染索引；
/// 2) 上层引用时不用再记忆字符串常量，直接传 [DictType.currency.code]。
///
/// 新增字典类型时只需追加一个枚举项 + 在 migration 里 seed 内置项。
enum DictType {
  transferProtocol('TRANSFER_PROTOCOL'),
  sovereigntyRegion('SOVEREIGNTY_REGION'),
  currency('CURRENCY');

  const DictType(this.code);
  final String code;

  static DictType fromCode(String code) => DictType.values.firstWhere(
        (e) => e.code == code,
        orElse: () => throw StorageError('unknown DictType: $code'),
      );
}
