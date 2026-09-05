import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../attendance/presentation/screens/batch_attendance_screen.dart';
import '../../../students/domain/student_models.dart' as student_domain;
import '../../../students/presentation/providers/student_providers.dart';
import '../../../teachers/domain/teacher_models.dart' as teacher_domain;
import '../../../teachers/presentation/providers/teacher_providers.dart';
import '../providers/batch_providers.dart';

class BatchDetailScreen extends ConsumerWidget {
  const BatchDetailScreen({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBatch = ref.watch(batchDetailProvider(batchId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Details'),
        actions: [
          asyncBatch.maybeWhen(
            data: (batch) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/batches/$batchId/edit'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncBatch.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load batch',
          onRetry: () => ref.invalidate(batchDetailProvider(batchId)),
        ),
        data: (batch) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(batch.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            if (batch.description != null) Text(batch.description!),
            const SizedBox(height: 8),
            StatusBadge(status: batch.status),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Take Attendance'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BatchAttendanceScreen(batchId: batchId, batchName: batch.name),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Teachers', style: Theme.of(context).textTheme.titleMedium),
                        TextButton(
                          onPressed: () => _showAssignTeacherDialog(context, ref, batchId),
                          child: const Text('Assign'),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (batch.teachers.isEmpty) const Text('No teachers assigned yet'),
                    for (final t in batch.teachers)
                      Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(t.name)),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Students', style: Theme.of(context).textTheme.titleMedium),
                        TextButton(
                          onPressed: () => _showAddStudentDialog(context, ref, batchId),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (batch.students.isEmpty) const Text('No students in this batch yet'),
                    for (final s in batch.students)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.fullName),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () async {
                            final confirmed = await confirmAction(
                              context,
                              title: 'Remove student?',
                              message: '${s.fullName} will be removed from this batch.',
                              confirmLabel: 'Remove',
                            );
                            if (!confirmed) return;
                            await ref.read(batchRepositoryProvider).removeStudents(batchId, [s.id]);
                            ref.invalidate(batchDetailProvider(batchId));
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.block),
              label: const Text('Deactivate Batch'),
              onPressed: batch.status == 'INACTIVE'
                  ? null
                  : () async {
                      final confirmed = await confirmAction(
                        context,
                        title: 'Deactivate batch?',
                        message: 'This can be reversed later by editing the batch.',
                        confirmLabel: 'Deactivate',
                      );
                      if (!confirmed) return;
                      await ref.read(batchRepositoryProvider).deactivate(batchId);
                      ref.invalidate(batchDetailProvider(batchId));
                      ref.read(batchListControllerProvider.notifier).load();
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddStudentDialog(BuildContext context, WidgetRef ref, String batchId) async {
    final selected = await showDialog<student_domain.Student>(
      context: context,
      builder: (context) => _StudentPickerDialog(),
    );
    if (selected == null) return;
    try {
      await ref.read(batchRepositoryProvider).addStudents(batchId, [selected.id]);
      ref.invalidate(batchDetailProvider(batchId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppException ? e.message : 'Failed to add student')),
        );
      }
    }
  }

  Future<void> _showAssignTeacherDialog(BuildContext context, WidgetRef ref, String batchId) async {
    final selected = await showDialog<teacher_domain.Teacher>(
      context: context,
      builder: (context) => _TeacherPickerDialog(),
    );
    if (selected == null) return;
    try {
      await ref.read(batchRepositoryProvider).assignTeachers(batchId, [selected.id]);
      ref.invalidate(batchDetailProvider(batchId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppException ? e.message : 'Failed to assign teacher')),
        );
      }
    }
  }
}

class _StudentPickerDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StudentPickerDialog> createState() => _StudentPickerDialogState();
}

class _StudentPickerDialogState extends ConsumerState<_StudentPickerDialog> {
  List<student_domain.Student> _results = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final result = await ref.read(studentRepositoryProvider).list(query: query);
    setState(() {
      _results = result.items;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Student'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Search students', isDense: true),
              onSubmitted: _search,
            ),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final s = _results[index];
                  return ListTile(
                    title: Text(s.fullName),
                    subtitle: Text(s.studentCode),
                    onTap: () => Navigator.pop(context, s),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}

class _TeacherPickerDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TeacherPickerDialog> createState() => _TeacherPickerDialogState();
}

class _TeacherPickerDialogState extends ConsumerState<_TeacherPickerDialog> {
  List<teacher_domain.Teacher> _results = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final result = await ref.read(teacherRepositoryProvider).list(query: query);
    setState(() {
      _results = result.items;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Teacher'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Search teachers', isDense: true),
              onSubmitted: _search,
            ),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final t = _results[index];
                  return ListTile(
                    title: Text(t.name),
                    onTap: () => Navigator.pop(context, t),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}
