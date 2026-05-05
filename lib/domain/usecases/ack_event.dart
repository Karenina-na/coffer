import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/event_enums.dart';
import '../repositories/event_repository.dart';

/// 用户对事件的确认 / 忽略操作。
///
/// 与 [EventRepository.updateHandling]（系统处理状态）正交。
class AckEventUseCase {
  const AckEventUseCase(this._events);
  final EventRepository _events;

  Future<Result<void, AppError>> confirm(String eventId, {String? note}) {
    if (eventId.trim().isEmpty) {
      return Future.value(const Err(ValidationError('事件 ID 不能为空')));
    }
    return _events.updateAck(
      id: eventId,
      ackStatus: AckStatus.confirmed,
      note: note,
    );
  }

  Future<Result<void, AppError>> dismiss(String eventId, {String? note}) {
    if (eventId.trim().isEmpty) {
      return Future.value(const Err(ValidationError('事件 ID 不能为空')));
    }
    return _events.updateAck(
      id: eventId,
      ackStatus: AckStatus.dismissed,
      note: note,
    );
  }
}
