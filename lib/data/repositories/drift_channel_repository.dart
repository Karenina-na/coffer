import '../../core/errors.dart';
import '../../core/result.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/channel_enums.dart';
import '../../domain/repositories/channel_repository.dart';
import '../db/daos/channel_dao.dart';
import '../db/daos/channel_mapper.dart';

class DriftChannelRepository implements ChannelRepository {
  DriftChannelRepository(
    this._dao, {
    ChannelMapper mapper = const ChannelMapper(),
    DateTime Function()? now,
  })  : _mapper = mapper,
        _now = now ?? DateTime.now;

  final ChannelDao _dao;
  final ChannelMapper _mapper;
  final DateTime Function() _now;

  @override
  Stream<List<Channel>> watchAll() => _dao
      .watchAll()
      .map((rows) => rows.map(_mapper.toDomain).toList(growable: false));

  @override
  Future<Result<Channel, AppError>> findById(String id) async {
    try {
      final row = await _dao.findById(id);
      if (row == null) return Err(NotFoundError('channel not found: $id'));
      return Ok(_mapper.toDomain(row));
    } catch (e) {
      return Err(StorageError('findById failed: $e'));
    }
  }

  @override
  Future<Result<Channel, AppError>> upsert(Channel channel) async {
    try {
      await _dao.upsert(_mapper.toInsert(channel));
      return Ok(channel);
    } catch (e) {
      return Err(StorageError('upsert failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> setStatus(
    String id,
    ChannelStatus status,
  ) async {
    try {
      final n = await _dao.setStatus(
        id: id,
        status: status.code,
        updatedAt: _now(),
      );
      if (n == 0) return Err(NotFoundError('channel not found: $id'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('setStatus failed: $e'));
    }
  }
}
