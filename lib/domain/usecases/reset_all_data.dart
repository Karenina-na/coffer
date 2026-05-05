import '../../core/auth/pin_store.dart';
import '../../core/errors.dart';
import '../../core/result.dart';
import '../repositories/db_snapshot_repository.dart';

/// 重置所有本地数据：
/// - 通过 [DbSnapshotRepository.truncateAll] 在单个事务里截断全部业务表；
/// - 可选：清空 `PinStore`（PIN 哈希 / 盐 / 失败计数 / 生物识别开关）；
/// - **不**删除 SQLCipher 主密钥（设备绑定、用于继续读写空库），也**不**删除
///   数据库文件本身——事务截断即可让下次查询返回空。
///
/// domain 层只依赖 [DbSnapshotRepository] 接口，具体截断实现由 data 层提供，
/// 保持 `presentation → domain ← data` 的单向分层。
class ResetAllDataUseCase {
  const ResetAllDataUseCase({
    required DbSnapshotRepository snapshot,
    required PinStore pinStore,
  })  : _snapshot = snapshot,
        _pin = pinStore;

  final DbSnapshotRepository _snapshot;
  final PinStore _pin;

  /// 执行重置。
  ///
  /// - [clearPin]：同时清空 PIN / 生物识别开关。默认 `false`——大多数用户只想
  ///   抹掉财务数据而继续用原 PIN；显式打开后下次启动会强制重新设置 PIN。
  Future<Result<void, AppError>> call({bool clearPin = false}) async {
    try {
      await _snapshot.truncateAll();
    } catch (e) {
      return Err(StorageError('清除数据失败：$e'));
    }

    if (clearPin) {
      try {
        await _pin.clear();
      } catch (e) {
        // DB 已清、PIN 清理失败：属于部分成功。向上抛 StorageError 让调用方
        // 提示用户"数据已清，但 PIN 未能重置"，避免悄悄吞错。
        return Err(StorageError('PIN 状态清除失败：$e'));
      }
    }
    return const Ok(null);
  }
}
