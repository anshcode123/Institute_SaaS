import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notification_repository_impl.dart';
import '../../domain/notification_models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => NotificationRepository());

final notificationsProvider = FutureProvider.autoDispose<NotificationsPage>((ref) async {
  return ref.watch(notificationRepositoryProvider).list();
});
