import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/asset.dart';
import '../entities/asset_enums.dart';

abstract interface class AssetRepository {
  /// 订阅全部未删除资产（所有账户），按创建时间倒序。
  Stream<List<Asset>> watchAll();

  /// 订阅指定账户下的未删除资产。
  Stream<List<Asset>> watchByAccount(String accountId);

  /// 订阅指定 id 的未删除资产；不存在或已软删除时发出 `null`。
  Stream<Asset?> watchById(String id);

  Future<Result<Asset, AppError>> findById(String id);

  Future<List<Result<Asset, AppError>>> findByIds(List<String> ids);

  Future<Result<Asset, AppError>> create(Asset asset);

  Future<Result<Asset, AppError>> update(Asset asset);

  Future<Result<void, AppError>> updateStatus(String id, AssetStatus status);

  Future<Result<void, AppError>> softDelete(String id);
}
