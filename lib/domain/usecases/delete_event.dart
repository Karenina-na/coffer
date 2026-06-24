import '../../core/errors.dart';
import '../../core/result.dart';
import '../repositories/event_repository.dart';

class DeleteEventUseCase {
  const DeleteEventUseCase(this._events);

  final EventRepository _events;

  Future<Result<void, AppError>> call(String id) {
    return _events.softDelete(id);
  }
}
