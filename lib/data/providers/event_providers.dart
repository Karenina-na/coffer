import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/daos/event_dao.dart';
import '../repositories/drift_event_repository.dart';
import '../../domain/events/event_bus.dart';
import '../../domain/repositories/event_repository.dart';
import 'account_providers.dart';

final domainEventBusProvider = Provider<DomainEventBus>((ref) {
  final bus = DomainEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final eventDaoProvider = Provider<EventDao>((ref) {
  return ref.watch(appDatabaseProvider).eventDao;
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return DriftEventRepository(ref.watch(eventDaoProvider));
});
