import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';

class UpdateAccountUseCase {
  const UpdateAccountUseCase(this._accounts);

  final AccountRepository _accounts;

  Future<Result<Account, AppError>> call(Account account) {
    if (account.institutionName.trim().isEmpty) {
      return Future.value(
        const Err(ValidationError('institutionName is required')),
      );
    }
    if (account.sovereigntyRegion.trim().isEmpty) {
      return Future.value(
        const Err(ValidationError('sovereigntyRegion is required')),
      );
    }
    return _accounts.update(account);
  }
}
