import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/providers/event_providers.dart';
import '../../../domain/entities/domain_event.dart';
import '../../../domain/usecases/ack_event.dart';
import '../../../domain/usecases/create_event.dart';

export '../../../data/providers/event_providers.dart'
    show domainEventBusProvider, eventDaoProvider, eventRepositoryProvider;

final recentEventsProvider = StreamProvider<List<DomainEvent>>((ref) {
  return ref.watch(eventRepositoryProvider).watchRecent();
});

/// 全局待确认事件（REQUIRED + PENDING，未软删除）。
final pendingAckEventsProvider = StreamProvider<List<DomainEvent>>((ref) {
  return ref.watch(eventRepositoryProvider).watchPendingAck();
});

/// 未确认事件计数，用于底部导航 Events Tab 角标。
final unreadEventCountProvider = Provider<int>((ref) {
  return ref.watch(pendingAckEventsProvider).maybeWhen(
        data: (list) => list.length,
        orElse: () => 0,
      );
});

final ackEventUseCaseProvider = Provider<AckEventUseCase>((ref) {
  return AckEventUseCase(ref.watch(eventRepositoryProvider));
});

final createEventUseCaseProvider = Provider<CreateEventUseCase>((ref) {
  return CreateEventUseCase(ref.watch(eventRepositoryProvider));
});

final uuidGeneratorProvider = Provider<String Function()>((_) {
  const uuid = Uuid();
  return uuid.v4;
});
