import '../../core/errors.dart';
import '../../core/result.dart';
import '../repositories/asset_repository.dart';

class DeleteAssetUseCase {
  const DeleteAssetUseCase(this._assets);

  final AssetRepository _assets;

  Future<Result<void, AppError>> call(String id) {
    return _assets.softDelete(id);
  }
}
