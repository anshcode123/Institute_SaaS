import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/grid_list_toggle.dart';
import '../providers/student_list_state.dart';
import '../providers/student_providers.dart';
import '../widgets/student_list_tile.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  RecordViewMode _viewMode = RecordViewMode.list;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentListControllerProvider);
    final controller = ref.read(studentListControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Students'), actions: [
        GridListToggle(value: _viewMode, onChanged: (value) => setState(() => _viewMode = value)),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/students/new'),
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
                      hintText: 'Search students',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: controller.setQuery,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: state.statusFilter,
                  hint: const Text('Status'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                    DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                  ],
                  onChanged: controller.setStatusFilter,
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(context, state, controller)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, StudentListState state, StudentListController controller) {
    switch (state.status) {
      case StudentListStatus.initial:
      case StudentListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case StudentListStatus.error:
        return ErrorState(message: state.errorMessage ?? 'Failed to load students', onRetry: controller.load);
      case StudentListStatus.loaded:
        if (state.items.isEmpty) {
          return const EmptyState(message: 'No students yet. Tap + to add one.', icon: Icons.school_outlined);
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: _viewMode == RecordViewMode.grid
              ? ResponsiveRecordGrid(
                  itemCount: state.items.length,
                  itemBuilder: (context, index) => StudentListTile(
                    student: state.items[index],
                    onTap: () => context.push('/students/${state.items[index].id}'),
                  ),
                )
              : ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 80),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final student = state.items[index];
              return StudentListTile(
                student: student,
                onTap: () => context.push('/students/${student.id}'),
              );
            },
                ),
        );
    }
  }
}
