import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/view_mode_provider.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/grid_list_toggle.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/teacher_list_state.dart';
import '../providers/teacher_providers.dart';
import '../widgets/teacher_grid_card.dart';

class TeachersListScreen extends ConsumerWidget {
  const TeachersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teacherListControllerProvider);
    final controller = ref.read(teacherListControllerProvider.notifier);
    final viewMode = ref.watch(viewModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Teachers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/teachers/new'),
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
                      hintText: 'Search teachers',
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
              TeacherListStatus.initial || TeacherListStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              TeacherListStatus.error => ErrorState(
                  message: state.errorMessage ?? 'Failed to load teachers',
                  onRetry: controller.load,
                ),
              TeacherListStatus.loaded => state.items.isEmpty
                  ? const EmptyState(message: 'No teachers yet. Tap + to add one.', icon: Icons.person_outline)
                  : viewMode == RecordViewMode.grid
                      ? ResponsiveRecordGrid(
                          itemCount: state.items.length,
                          itemBuilder: (context, index) {
                            final teacher = state.items[index];
                            return TeacherGridCard(
                              teacher: teacher,
                              onTap: () => context.push('/teachers/${teacher.id}'),
                            );
                          },
                        )
                      : RefreshIndicator(
                          onRefresh: controller.load,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: state.items.length,
                            itemBuilder: (context, index) {
                              final teacher = state.items[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: ListTile(
                                  onTap: () => context.push('/teachers/${teacher.id}'),
                                  leading: CircleAvatar(
                                    backgroundImage: teacher.profilePhoto != null
                                        ? NetworkImage(teacher.profilePhoto!)
                                        : null,
                                    child: teacher.profilePhoto == null ? Text(teacher.name[0]) : null,
                                  ),
                                  title: Text(teacher.name),
                                  subtitle: Text(teacher.phone ?? teacher.email ?? ''),
                                  trailing: StatusBadge(status: teacher.status),
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
