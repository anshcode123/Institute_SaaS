import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/grid_list_toggle.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/parent_list_state.dart';
import '../providers/parent_providers.dart';

class ParentsListScreen extends ConsumerStatefulWidget {
  const ParentsListScreen({super.key});

  @override
  ConsumerState<ParentsListScreen> createState() => _ParentsListScreenState();
}

class _ParentsListScreenState extends ConsumerState<ParentsListScreen> {
  RecordViewMode _viewMode = RecordViewMode.list;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentListControllerProvider);
    final controller = ref.read(parentListControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Parents'), actions: [
        GridListToggle(value: _viewMode, onChanged: (value) => setState(() => _viewMode = value)),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/parents/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search parents',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: controller.setQuery,
            ),
          ),
          Expanded(
            child: switch (state.status) {
              ParentListStatus.initial || ParentListStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              ParentListStatus.error => ErrorState(
                  message: state.errorMessage ?? 'Failed to load parents',
                  onRetry: controller.load,
                ),
              ParentListStatus.loaded => state.items.isEmpty
                  ? const EmptyState(message: 'No parents yet. Tap + to add one.', icon: Icons.people_outline)
                  : RefreshIndicator(
                      onRefresh: controller.load,
                      child: _viewMode == RecordViewMode.grid
                          ? ResponsiveRecordGrid(
                              itemCount: state.items.length,
                              itemBuilder: (context, index) {
                                final parent = state.items[index];
                                return Card(
                                  child: InkWell(
                                    onTap: () => context.push('/parents/${parent.id}'),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(parent.name, style: Theme.of(context).textTheme.titleMedium),
                                          const SizedBox(height: 8),
                                          Text(parent.phone ?? parent.email ?? ''),
                                          const Spacer(),
                                          StatusBadge(status: parent.status),
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
                          final parent = state.items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              onTap: () => context.push('/parents/${parent.id}'),
                              title: Text(parent.name),
                              subtitle: Text(parent.phone ?? parent.email ?? ''),
                              trailing: StatusBadge(status: parent.status),
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
