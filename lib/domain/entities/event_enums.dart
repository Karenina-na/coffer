import '../../core/errors.dart';

/// 关联模型类型，对齐 doc/data-definitions.md §7 `related_model`。
enum RelatedModel {
  account('ACCOUNT'),
  asset('ASSET'),
  card('CARD'),
  channel('CHANNEL');

  const RelatedModel(this.code);
  final String code;

  static RelatedModel fromCode(String code) => RelatedModel.values.firstWhere(
        (e) => e.code == code,
        orElse: () => throw StorageError('unknown RelatedModel: $code'),
      );
}

enum EventPriority {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH'),
  critical('CRITICAL');

  const EventPriority(this.code);
  final String code;

  static EventPriority? fromCodeOrNull(String? code) => code == null
      ? null
      : EventPriority.values.firstWhere(
          (e) => e.code == code,
          orElse: () => throw StorageError('unknown EventPriority: $code'),
        );
}

enum EventStatus {
  pending('PENDING'),
  triggered('TRIGGERED'),
  resolved('RESOLVED'),
  closed('CLOSED');

  const EventStatus(this.code);
  final String code;

  static EventStatus fromCode(String code) => EventStatus.values.firstWhere(
        (e) => e.code == code,
        orElse: () => throw StorageError('unknown EventStatus: $code'),
      );
}

enum HandlingStatus {
  unhandled('UNHANDLED'),
  processing('PROCESSING'),
  handled('HANDLED'),
  failed('FAILED');

  const HandlingStatus(this.code);
  final String code;

  static HandlingStatus? fromCodeOrNull(String? code) => code == null
      ? null
      : HandlingStatus.values.firstWhere(
          (e) => e.code == code,
          orElse: () => throw StorageError('unknown HandlingStatus: $code'),
        );
}

/// 用户视角：事件是否需要确认。与 [HandlingStatus] 正交。
///
/// - [notApplicable]：系统合成事件（如估值刷新），无需用户介入
/// - [optional]：允许用户标记为已看过，但不强制
/// - [required]：必须由用户确认或忽略（对账、到期、异常等）
enum AckRequirement {
  notApplicable('NOT_APPLICABLE'),
  optional('OPTIONAL'),
  required_('REQUIRED');

  const AckRequirement(this.code);
  final String code;

  static AckRequirement fromCode(String code) => AckRequirement.values.firstWhere(
        (e) => e.code == code,
        orElse: () => throw StorageError('unknown AckRequirement: $code'),
      );

  static AckRequirement fromCodeOrDefault(String? code) =>
      code == null ? AckRequirement.notApplicable : fromCode(code);
}

/// 用户视角：事件当前的确认状态。
///
/// - [pending]：待确认 / 未处理
/// - [confirmed]：用户已确认（对账无误 / 已处理）
/// - [dismissed]：用户已忽略（不关心 / 误报）
enum AckStatus {
  pending('PENDING'),
  confirmed('CONFIRMED'),
  dismissed('DISMISSED');

  const AckStatus(this.code);
  final String code;

  static AckStatus fromCode(String code) => AckStatus.values.firstWhere(
        (e) => e.code == code,
        orElse: () => throw StorageError('unknown AckStatus: $code'),
      );

  static AckStatus fromCodeOrDefault(String? code) =>
      code == null ? AckStatus.pending : fromCode(code);
}
