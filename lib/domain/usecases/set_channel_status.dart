import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/channel_enums.dart';
import '../repositories/channel_repository.dart';

class SetChannelStatusUseCase {
  const SetChannelStatusUseCase(this._channels);

  final ChannelRepository _channels;

  Future<Result<void, AppError>> call(String id, ChannelStatus status) {
    return _channels.setStatus(id, status);
  }
}
