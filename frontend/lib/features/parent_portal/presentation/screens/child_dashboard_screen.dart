import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/currency_text.dart';
import '../../../../shared/widgets/error_state.dart';
import '../providers/parent_portal_providers.dart';

/// Everything on this screen and everything it links to is scoped to
/// this one studentId - and the backend independently re-verifies the
/// parent-child link on every single one of those calls, not just this
/// dashboard fetch.
class ChildDashboardScreen extends ConsumerWidget {
  const ChildDashboardScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDashboard = ref.watch(childDashboardProvider(studentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Child Dashboard')),
      body: asyncDashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load dashboard',
          onRetry: () => ref.invalidate(childDashboardProvider(studentId)),
        ),
        data: (dashboard) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (dashboard.attendanceSummary != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Attendance'),
                      Text(
                        '${dashboard.attendanceSummary!.percentage}% '
                        '(${dashboard.attendanceSummary!.present}/${dashboard.attendanceSummary!.total})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Outstanding Fees'),
                    Text(
                      formatCurrency(dashboard.feesSummary.outstandingAmount),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
            if (dashboard.latestResult != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Latest Result'),
                      Text(
                        '${dashboard.latestResult!.percentage}% • ${dashboard.latestResult!.grade} • ${dashboard.latestResult!.status}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: dashboard.latestResult!.status == 'PASS'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _NavTile(
              icon: Icons.event_available_outlined,
              label: 'Attendance',
              onTap: () =>
                  context.push('/parent/children/$studentId/attendance'),
            ),
            _NavTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Fees & Receipts',
              onTap: () => context.push('/parent/children/$studentId/fees'),
            ),
            _NavTile(
              icon: Icons.quiz_outlined,
              label: 'Tests & Results',
              onTap: () => context.push('/parent/children/$studentId/results'),
            ),
            _NavTile(
              icon: Icons.campaign_outlined,
              label: 'Announcements',
              onTap: () =>
                  context.push('/parent/children/$studentId/announcements'),
            ),
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
