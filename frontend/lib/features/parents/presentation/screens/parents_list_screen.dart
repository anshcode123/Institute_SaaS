import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/view_mode_provider.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/grid_list_toggle.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/parent_list_state.dart';
import '../providers/parent_providers.dart';
import '../widgets/parent_grid_card.dart';

class ParentsListScreen extends ConsumerWidget {
  const ParentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(parentListControllerProvider);
    final controller = ref.read(parentListControllerProvider.notifier);
    final viewMode = ref.watch(viewModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Parents')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/parents/new'),
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
                      hintText: 'Search parents',
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
              ParentListStatus.initial || ParentListStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              ParentListStatus.error => ErrorState(
                  message: state.errorMessage ?? 'Failed to load parents',
                  onRetry: controller.load,
                ),
              ParentListStatus.loaded => state.items.isEmpty
                  ? const EmptyState(message: 'No parents yet. Tap + to add one.', icon: Icons.people_outline)
                  : viewMode == RecordViewMode.grid
                      ? ResponsiveRecordGrid(
                          itemCount: state.items.length,
                          itemBuilder: (context, index) {
                            final parent = state.items[index];
                            return ParentGridCard(
                              parent: parent,
                              onTap: () => context.push('/parents/${parent.id}'),
                            );
                          },
                        )
                      : RefreshIndicator(
                          onRefresh: controller.load,
                          child: ListView.builder(
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
