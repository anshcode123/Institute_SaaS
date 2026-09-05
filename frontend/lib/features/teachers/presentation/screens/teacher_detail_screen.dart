import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/teacher_providers.dart';

class TeacherDetailScreen extends ConsumerWidget {
  const TeacherDetailScreen({super.key, required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTeacher = ref.watch(teacherDetailProvider(teacherId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Details'),
        actions: [
          asyncTeacher.maybeWhen(
            data: (teacher) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/teachers/$teacherId/edit'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncTeacher.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load teacher',
          onRetry: () => ref.invalidate(teacherDetailProvider(teacherId)),
        ),
        data: (teacher) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(teacher.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            StatusBadge(status: teacher.status),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phone: ${teacher.phone ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('Email: ${teacher.email ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('Address: ${teacher.address ?? '-'}'),
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
                    Text('Assigned Batches', style: Theme.of(context).textTheme.titleMedium),
                    const Divider(),
                    if (teacher.batches.isEmpty) const Text('No batches assigned yet'),
                    for (final b in teacher.batches)
                      Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(b.name)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Login Account', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            teacher.hasLogin
                                ? 'This teacher can log in and mark attendance'
                                : 'Lets this teacher log in and mark attendance',
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: teacher.hasLogin ? null : () => _createLogin(context, ref),
                      child: const Text('Create Login'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.block),
              label: const Text('Deactivate Teacher'),
              onPressed: teacher.status == 'INACTIVE'
                  ? null
                  : () async {
                      final confirmed = await confirmAction(
                        context,
                        title: 'Deactivate teacher?',
                        message: 'This can be reversed later by editing the teacher.',
                        confirmLabel: 'Deactivate',
                      );
                      if (!confirmed) return;
                      await ref.read(teacherRepositoryProvider).deactivate(teacherId);
                      ref.invalidate(teacherDetailProvider(teacherId));
                      ref.read(teacherListControllerProvider.notifier).load();
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createLogin(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref.read(teacherRepositoryProvider).createLogin(teacherId);
      ref.invalidate(teacherDetailProvider(teacherId));
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Login Created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Save these credentials now - the password will not be shown again.'),
              const SizedBox(height: 16),
              SelectableText('Email: ${result['email']}'),
              const SizedBox(height: 4),
              SelectableText('Password: ${result['initialPassword']}'),
            ],
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is AppException ? e.message : 'Failed to create login')),
      );
    }
  }
}
