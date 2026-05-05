import '../../core/errors.dart';

enum SnapshotType {
  realtime('REALTIME'),
  hourly('HOURLY'),
  daily('DAILY');

  const SnapshotType(this.code);
  final String code;

  static SnapshotType fromCode(String code) => SnapshotType.values.firstWhere(
        (e) => e.code == code,
        orElse: () => throw StorageError('unknown SnapshotType: $code'),
      );
}
