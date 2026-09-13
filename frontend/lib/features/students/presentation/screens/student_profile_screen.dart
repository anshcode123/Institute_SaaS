import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/currency_text.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../fees/presentation/providers/fee_providers.dart';
import '../../../fees/presentation/widgets/fee_status_chip.dart';
import '../../../tests/presentation/providers/test_providers.dart';
import '../../domain/student_models.dart';
import '../providers/student_providers.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStudent = ref.watch(studentDetailProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
          asyncStudent.maybeWhen(
            data: (student) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/students/$studentId/edit'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncStudent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load student',
          onRetry: () => ref.invalidate(studentDetailProvider(studentId)),
        ),
        data: (student) => _ProfileBody(student: student, studentId: studentId),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.student, required this.studentId});

  final Student student;
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat.yMMMd();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundImage: student.profilePhoto != null
                    ? NetworkImage(student.profilePhoto!)
                    : null,
                child: student.profilePhoto == null
                    ? Text(student.firstName[0],
                        style: const TextStyle(fontSize: 32))
                    : null,
              ),
              const SizedBox(height: 12),
              Text(student.fullName,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              StatusBadge(status: student.status),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _InfoCard(
          title: 'Details',
          rows: [
            _InfoRow('Student ID', student.studentCode),
            _InfoRow('Batch', student.batch?.name ?? 'Not assigned'),
            _InfoRow('Phone', student.phone ?? '-'),
            _InfoRow('Email', student.email ?? '-'),
            _InfoRow(
              'Date of Birth',
              student.dateOfBirth != null
                  ? dateFormat.format(student.dateOfBirth!)
                  : '-',
            ),
            _InfoRow('Address', student.address ?? '-'),
            _InfoRow(
                'Admission Date', dateFormat.format(student.admissionDate)),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Parent / Guardian',
          rows: student.parents.isEmpty
              ? [const _InfoRow('-', 'No parent linked yet')]
              : student.parents
                  .map((p) => _InfoRow(p.relationship,
                      '${p.name}${p.phone != null ? ' - ${p.phone}' : ''}'))
                  .toList(),
          trailing: TextButton(
            onPressed: () => context.push('/students/$studentId/link-parent'),
            child: const Text('Link parent'),
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
                      Text('Login Account',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        student.hasLogin
                            ? 'Student can sign in (${student.loginEmail ?? student.email})'
                            : 'Enable portal access for this student',
                      ),
                    ],
                  ),
                ),
                if (!student.hasLogin)
                  FilledButton(
                    onPressed: () => _createLogin(context, ref),
                    child: const Text('Create Login'),
                  )
                else
                  OutlinedButton(
                    onPressed: () => _resetPassword(context, ref),
                    child: const Text('Reset Password'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _AttendanceSummaryCard(studentId: studentId),
        const SizedBox(height: 12),
        _StudentFeesCard(studentId: studentId),
        const SizedBox(height: 12),
        _StudentTestsCard(studentId: studentId),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.block),
          label: const Text('Deactivate Student'),
          onPressed: student.status == 'INACTIVE'
              ? null
              : () async {
                  final confirmed = await confirmAction(
                    context,
                    title: 'Deactivate student?',
                    message:
                        'This can be reversed later by editing the student.',
                    confirmLabel: 'Deactivate',
                  );
                  if (!confirmed) return;
                  await ref
                      .read(studentRepositoryProvider)
                      .deactivate(studentId);
                  ref.invalidate(studentDetailProvider(studentId));
                  ref.read(studentListControllerProvider.notifier).load();
                },
        ),
      ],
    );
  }

  Future<void> _createLogin(BuildContext context, WidgetRef ref) async {
    final loginIdController = TextEditingController(text: student.email ?? '');
    final passwordController = TextEditingController();

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Student Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: loginIdController,
              decoration: const InputDecoration(
                labelText: 'Login ID / Email',
                hintText: 'student@example.com',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password (leave blank to auto-generate)',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (shouldCreate != true || !context.mounted) return;

    try {
      final result = await ref.read(studentRepositoryProvider).createLogin(
            studentId,
            loginId: loginIdController.text.trim().isEmpty
                ? null
                : loginIdController.text.trim(),
            password: passwordController.text.trim().isEmpty
                ? null
                : passwordController.text.trim(),
          );
      ref.invalidate(studentDetailProvider(studentId));
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
              const Text(
                  'Save these credentials now - the password will not be shown again.'),
              const SizedBox(height: 16),
              SelectableText('Login ID / Email: ${result['email']}'),
              const SizedBox(height: 4),
              SelectableText('Password: ${result['initialPassword']}'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e is AppException ? e.message : 'Failed to create login')),
      );
    }
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref) async {
    final passwordController = TextEditingController();

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Student Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password (leave blank to auto-generate)',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (shouldReset != true || !context.mounted) return;

    try {
      final result = await ref.read(studentRepositoryProvider).resetPassword(
            studentId,
            newPassword: passwordController.text.trim().isEmpty
                ? null
                : passwordController.text.trim(),
          );
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Password Reset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New credentials for student:'),
              const SizedBox(height: 16),
              SelectableText('Login ID / Email: ${result['email']}'),
              const SizedBox(height: 4),
              SelectableText('New Password: ${result['newPassword']}'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                e is AppException ? e.message : 'Failed to reset password')),
      );
    }
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows, this.trailing});

  final String title;
  final List<_InfoRow> rows;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (trailing != null) trailing!,
              ],
            ),
            const Divider(),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                        width: 130,
                        child: Text(row.label,
                            style: const TextStyle(color: Colors.grey))),
                    Expanded(child: Text(row.value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceSummaryCard extends ConsumerWidget {
  const _AttendanceSummaryCard({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummary = ref.watch(studentAttendanceSummaryProvider(studentId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Attendance',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () =>
                      context.push('/attendance/history?studentId=$studentId'),
                  child: const Text('View history'),
                ),
              ],
            ),
            const Divider(),
            asyncSummary.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => const Text('Attendance data unavailable'),
              data: (summary) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statChip('Total', summary.total.toString()),
                      _statChip('Present', summary.present.toString(),
                          color: Colors.green),
                      _statChip('Absent', summary.absent.toString(),
                          color: Colors.red),
                      _statChip('Late', summary.late.toString(),
                          color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Attendance: ${summary.percentage}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _StudentFeesCard extends ConsumerWidget {
  const _StudentFeesCard({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFees = ref.watch(feesForStudentProvider(studentId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fees', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () =>
                      context.push('/fees/assign?studentId=$studentId'),
                  child: const Text('Assign fee'),
                ),
              ],
            ),
            const Divider(),
            asyncFees.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => const Text('Fee data unavailable'),
              data: (result) {
                if (result.fees.isEmpty) {
                  return const Text('No fees assigned yet.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Total: ${formatCurrency(result.summary.finalAmount)}'),
                        Text(
                          'Outstanding: ${formatCurrency(result.summary.outstandingAmount)}',
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final fee in result.fees)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(fee.feeStructureName),
                        subtitle: Text(
                          'Paid ${formatCurrency(fee.paidAmount)} of ${formatCurrency(fee.finalAmount)}',
                        ),
                        trailing: FeeStatusChip(status: fee.status),
                        onTap: () => context.push('/fees/${fee.id}'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentTestsCard extends ConsumerWidget {
  const _StudentTestsCard({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResults = ref.watch(studentResultsProvider(studentId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tests & Results',
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            asyncResults.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => const Text('Test data unavailable'),
              data: (results) {
                if (results.isEmpty) {
                  return const Text('No test results yet.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final result in results)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                            '${result.obtainedMarks} / ${result.totalMarks}'),
                        subtitle: Text(
                            '${result.percentage}% • Grade ${result.grade}'),
                        trailing: Text(
                          result.status,
                          style: TextStyle(
                            color: result.status == 'PASS'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => context
                            .push('/students/$studentId/results/${result.id}'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
