import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case 'ATTENDANCE_CHECK_IN':
        return Icons.login;
      case 'ATTENDANCE_CHECK_OUT':
        return Icons.logout;
      case 'RESULT_PUBLISHED':
        return Icons.grade_outlined;
      case 'PAYMENT_RECEIVED':
        return Icons.payments_outlined;
      case 'FEE_DUE':
        return Icons.account_balance_wallet_outlined;
      case 'ANNOUNCEMENT':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: asyncNotifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load notifications',
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return const EmptyState(message: 'No notifications yet.', icon: Icons.notifications_none);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.builder(
              itemCount: page.items.length,
              itemBuilder: (context, index) {
                final n = page.items[index];
                return ListTile(
                  leading: Icon(
                    _iconFor(n.type),
                    color: n.isUnread ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                  title: Text(n.title, style: TextStyle(fontWeight: n.isUnread ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text('${n.message}\n${DateFormat.yMMMd().add_jm().format(n.createdAt)}'),
                  isThreeLine: true,
                  trailing: n.isUnread ? const Icon(Icons.circle, size: 10, color: Colors.blue) : null,
                  onTap: () async {
                    if (n.isUnread) {
                      await ref.read(notificationRepositoryProvider).markRead(n.id);
                      ref.invalidate(notificationsProvider);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
