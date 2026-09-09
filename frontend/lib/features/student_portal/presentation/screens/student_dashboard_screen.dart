import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../shared/widgets/currency_text.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../attendance/domain/attendance_models.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../fees/domain/fee_models.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../tests/domain/test_models.dart';
import '../providers/student_portal_providers.dart';

/// The Student Portal home screen. This is the ONLY thing a STUDENT
/// login ever sees post-login - the router (see app_router.dart) sends
/// STUDENT role straight here instead of the Institute Admin/Teacher
/// Home screen.
class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDashboard = ref.watch(myDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: asyncDashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load dashboard',
          onRetry: () => ref.invalidate(myDashboardProvider),
        ),
        data: (dashboard) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(myDashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(dashboard.student.fullName,
                  style: Theme.of(context).textTheme.headlineSmall),
              Text(dashboard.student.studentCode,
                  style: const TextStyle(color: Colors.grey)),
              if (dashboard.student.batch != null)
                Text('Batch: ${dashboard.student.batch!.name}'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Attendance QR'),
                      onPressed: () => _showQr(
                          context, dashboard.student.qrCode, 'Attendance QR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Leaving QR'),
                      onPressed: () => context.push('/student/leaving-qr'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (dashboard.attendanceSummary != null)
                _AttendanceCard(summary: dashboard.attendanceSummary!),
              const SizedBox(height: 12),
              _FeesCard(summary: dashboard.feesSummary),
              const SizedBox(height: 12),
              if (dashboard.latestResult != null)
                _LatestResultCard(result: dashboard.latestResult!),
              const SizedBox(height: 20),
              _NavTile(
                  icon: Icons.event_available_outlined,
                  label: 'Attendance History',
                  onTap: () => context.push('/student/attendance-history')),
              _NavTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Fees & Receipts',
                  onTap: () => context.push('/student/fees')),
              _NavTile(
                  icon: Icons.quiz_outlined,
                  label: 'Tests & Results',
                  onTap: () => context.push('/student/results')),
              _NavTile(
                  icon: Icons.campaign_outlined,
                  label: 'Announcements',
                  onTap: () => context.push('/student/announcements')),
            ],
          ),
        ),
      ),
    );
  }

  void _showQr(BuildContext context, String? qrData, String title) {
    if (qrData == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 260,
          height: 260,
          child: QrImageView(data: qrData, version: QrVersions.auto),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.summary});
  final StudentAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Attendance'),
            Text('${summary.percentage}% (${summary.present}/${summary.total})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _FeesCard extends StatelessWidget {
  const _FeesCard({required this.summary});
  final StudentFeesSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Outstanding Fees'),
            Text(formatCurrency(summary.outstandingAmount),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.orange)),
          ],
        ),
      ),
    );
  }
}

class _LatestResultCard extends StatelessWidget {
  const _LatestResultCard({required this.result});
  final StudentTestResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Latest Result'),
            Text('${result.percentage}% • ${result.grade} • ${result.status}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        result.status == 'PASS' ? Colors.green : Colors.red)),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap),
    );
  }
}
