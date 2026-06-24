import '../../core/errors.dart';
import '../../core/result.dart';
import '../repositories/account_repository.dart';

class DeleteAccountUseCase {
  const DeleteAccountUseCase(this._accounts);

  final AccountRepository _accounts;

  Future<Result<void, AppError>> call(String id) {
    return _accounts.softDelete(id);
  }
}
