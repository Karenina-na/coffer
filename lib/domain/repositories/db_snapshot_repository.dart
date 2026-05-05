/// 备份快照仓储接口。
///
/// 将数据库整体序列化为 `表名 → 行 JSON 列表` 的映射；
/// 恢复时以事务覆盖。具体实现放在 data 层，domain 层只依赖接口，
/// 保持 `presentation → domain ← data` 的单向分层。
abstract class DbSnapshotRepository {
  /// 导出全部业务表为 JSON 快照。
  Future<Map<String, List<Map<String, dynamic>>>> export();

  /// 以快照覆盖当前数据库（事务保证原子性）。
  Future<void> restore(Map<String, List<Map<String, dynamic>>> snap);

  /// 在单个事务里截断全部业务表（按 child → parent 顺序避免外键冲突）。
  Future<void> truncateAll();
}
