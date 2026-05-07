import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/domain_event.dart';
import '../repositories/event_repository.dart';

class CreateEventUseCase {
  const CreateEventUseCase(this._repo);

  final EventRepository _repo;

  Future<Result<DomainEvent, AppError>> call(DomainEvent event) {
    if (event.eventType.trim().isEmpty) {
      return Future.value(const Err(ValidationError('事件类型不能为空')));
    }
    if (event.relatedId.trim().isEmpty) {
      return Future.value(const Err(ValidationError('关联对象 ID 不能为空')));
    }
    return _repo.record(
      event.copyWith(
        eventType: event.eventType.trim(),
        relatedId: event.relatedId.trim(),
        handler: event.handler?.trim().isEmpty == true ? null : event.handler?.trim(),
        handlingNote: event.handlingNote?.trim().isEmpty == true
            ? null
            : event.handlingNote?.trim(),
      ),
    );
  }
}
