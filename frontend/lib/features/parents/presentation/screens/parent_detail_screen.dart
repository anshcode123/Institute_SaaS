import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/parent_providers.dart';

class ParentDetailScreen extends ConsumerWidget {
  const ParentDetailScreen({super.key, required this.parentId});

  final String parentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncParent = ref.watch(parentDetailProvider(parentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Details'),
        actions: [
          asyncParent.maybeWhen(
            data: (parent) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/parents/$parentId/edit'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncParent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load parent',
          onRetry: () => ref.invalidate(parentDetailProvider(parentId)),
        ),
        data: (parent) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(parent.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            StatusBadge(status: parent.status),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phone: ${parent.phone ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('Email: ${parent.email ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('Address: ${parent.address ?? '-'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Linked Students', style: Theme.of(context).textTheme.titleMedium),
                    const Divider(),
                    if (parent.students.isEmpty) const Text('No students linked yet'),
                    for (final s in parent.students)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${s.fullName} (${s.relationship})'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.block),
              label: const Text('Deactivate Parent'),
              onPressed: parent.status == 'INACTIVE'
                  ? null
                  : () async {
                      final confirmed = await confirmAction(
                        context,
                        title: 'Deactivate parent?',
                        message: 'This can be reversed later by editing the parent.',
                        confirmLabel: 'Deactivate',
                      );
                      if (!confirmed) return;
                      await ref.read(parentRepositoryProvider).deactivate(parentId);
                      ref.invalidate(parentDetailProvider(parentId));
                      ref.read(parentListControllerProvider.notifier).load();
                    },
            ),
          ],
        ),
      ),
    );
  }
}
