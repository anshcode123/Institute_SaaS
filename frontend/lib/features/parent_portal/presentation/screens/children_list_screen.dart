import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../providers/parent_portal_providers.dart';

/// The Parent Portal home screen - "Select Child" from the spec. If a
/// parent has exactly one linked child this could auto-navigate, but
/// showing the list either way keeps the flow identical and predictable
/// for one child or several.
class ChildrenListScreen extends ConsumerWidget {
  const ChildrenListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChildren = ref.watch(myChildrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: asyncChildren.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
            message: 'Failed to load children',
            onRetry: () => ref.invalidate(myChildrenProvider)),
        data: (children) {
          if (children.isEmpty) {
            return const EmptyState(
                message: 'No children linked to this account yet.',
                icon: Icons.family_restroom);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(child.fullName),
                  subtitle: Text(
                      '${child.studentCode}${child.batchName != null ? ' • ${child.batchName}' : ''}'),
                  trailing: StatusBadge(status: child.status),
                  onTap: () => context.push('/parent/children/${child.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
