import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/event_enums.dart';
import '../repositories/event_repository.dart';

class UpdateEventHandlingUseCase {
  const UpdateEventHandlingUseCase(this._events);

  final EventRepository _events;

  Future<Result<void, AppError>> call({
    required String id,
    required HandlingStatus status,
    String? handler,
    String? note,
  }) {
    return _events.updateHandling(
      id: id,
      status: status,
      handler: handler,
      note: note,
    );
  }
}
