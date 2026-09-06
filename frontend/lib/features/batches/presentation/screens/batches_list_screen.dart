import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/view_mode_provider.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/grid_list_toggle.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/batch_list_state.dart';
import '../providers/batch_providers.dart';
import '../widgets/batch_grid_card.dart';

class BatchesListScreen extends ConsumerWidget {
  const BatchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(batchListControllerProvider);
    final controller = ref.read(batchListControllerProvider.notifier);
    final viewMode = ref.watch(viewModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Batches')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/batches/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search batches',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: controller.setQuery,
                  ),
                ),
                const SizedBox(width: 8),
                GridListToggle(
                  value: viewMode,
                  onChanged: ref.read(viewModeProvider.notifier).setViewMode,
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (state.status) {
              BatchListStatus.initial || BatchListStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              BatchListStatus.error => ErrorState(
                  message: state.errorMessage ?? 'Failed to load batches',
                  onRetry: controller.load,
                ),
              BatchListStatus.loaded => state.items.isEmpty
                  ? const EmptyState(message: 'No batches yet. Tap + to create one.', icon: Icons.groups_outlined)
                  : viewMode == RecordViewMode.grid
                      ? ResponsiveRecordGrid(
                          itemCount: state.items.length,
                          itemBuilder: (context, index) {
                            final batch = state.items[index];
                            return BatchGridCard(
                              batch: batch,
                              onTap: () => context.push('/batches/${batch.id}'),
                            );
                          },
                        )
                      : RefreshIndicator(
                          onRefresh: controller.load,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: state.items.length,
                            itemBuilder: (context, index) {
                              final batch = state.items[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: ListTile(
                                  onTap: () => context.push('/batches/${batch.id}'),
                                  title: Text(batch.name),
                                  subtitle: Text(
                                    batch.studentCount != null ? '${batch.studentCount} students' : '',
                                  ),
                                  trailing: StatusBadge(status: batch.status),
                                ),
                              );
                            },
                          ),
                        ),
            },
          ),
        ],
      ),
    );
  }
}
