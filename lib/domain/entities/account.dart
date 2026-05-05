import 'package:freezed_annotation/freezed_annotation.dart';

import 'account_enums.dart';

part 'account.freezed.dart';

/// 账户领域模型（不可变）。
///
/// 与 Drift 行 `AccountRow` 解耦，对外仅暴露此类型。
/// 字段对齐 doc/data-definitions.md §2。
@freezed
abstract class Account with _$Account {
  const factory Account({
    required String id,
    String? accountNo,
    required AccountType accountType,
    required String sovereigntyRegion,
    required String institutionName,
    required AccountStatus status,
    DateTime? openedAt,
    Map<String, dynamic>? extInfo,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isDeleted,
  }) = _Account;
}
