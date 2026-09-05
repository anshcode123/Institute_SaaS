import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/grid_list_toggle.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/batch_list_state.dart';
import '../providers/batch_providers.dart';

class BatchesListScreen extends ConsumerStatefulWidget {
  const BatchesListScreen({super.key});

  @override
  ConsumerState<BatchesListScreen> createState() => _BatchesListScreenState();
}

class _BatchesListScreenState extends ConsumerState<BatchesListScreen> {
  RecordViewMode _viewMode = RecordViewMode.list;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchListControllerProvider);
    final controller = ref.read(batchListControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Batches'), actions: [
        GridListToggle(value: _viewMode, onChanged: (value) => setState(() => _viewMode = value)),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/batches/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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
                  : RefreshIndicator(
                      onRefresh: controller.load,
                      child: _viewMode == RecordViewMode.grid
                          ? ResponsiveRecordGrid(
                              itemCount: state.items.length,
                              itemBuilder: (context, index) {
                                final batch = state.items[index];
                                return Card(
                                  child: InkWell(
                                    onTap: () => context.push('/batches/${batch.id}'),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(batch.name, style: Theme.of(context).textTheme.titleMedium),
                                          const SizedBox(height: 8),
                                          Text(batch.studentCount != null ? '${batch.studentCount} students' : 'No students'),
                                          const Spacer(),
                                          StatusBadge(status: batch.status),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
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
