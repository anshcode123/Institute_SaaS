import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/grid_list_toggle.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/teacher_list_state.dart';
import '../providers/teacher_providers.dart';

class TeachersListScreen extends ConsumerStatefulWidget {
  const TeachersListScreen({super.key});

  @override
  ConsumerState<TeachersListScreen> createState() => _TeachersListScreenState();
}

class _TeachersListScreenState extends ConsumerState<TeachersListScreen> {
  RecordViewMode _viewMode = RecordViewMode.list;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherListControllerProvider);
    final controller = ref.read(teacherListControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Teachers'), actions: [
        GridListToggle(value: _viewMode, onChanged: (value) => setState(() => _viewMode = value)),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/teachers/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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
                  : RefreshIndicator(
                      onRefresh: controller.load,
                      child: _viewMode == RecordViewMode.grid
                          ? ResponsiveRecordGrid(
                              itemCount: state.items.length,
                              itemBuilder: (context, index) {
                                final teacher = state.items[index];
                                return Card(
                                  child: InkWell(
                                    onTap: () => context.push('/teachers/${teacher.id}'),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: teacher.profilePhoto != null ? NetworkImage(teacher.profilePhoto!) : null,
                                            child: teacher.profilePhoto == null ? Text(teacher.name[0]) : null,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(teacher.name, style: Theme.of(context).textTheme.titleMedium),
                                          const SizedBox(height: 4),
                                          Text(teacher.phone ?? teacher.email ?? ''),
                                          const Spacer(),
                                          StatusBadge(status: teacher.status),
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
