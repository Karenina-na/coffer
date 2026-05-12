import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/channel.dart';
import '../entities/channel_enums.dart';

abstract interface class ChannelRepository {
  Stream<List<Channel>> watchAll();

  Future<Result<Channel, AppError>> findById(String id);

  Future<Result<Channel, AppError>> upsert(Channel channel);

  Future<Result<void, AppError>> setStatus(String id, ChannelStatus status);

  Future<Result<void, AppError>> reorder(List<String> channelIds);
}
