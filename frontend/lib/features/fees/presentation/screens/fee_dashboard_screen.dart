import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/currency_text.dart';
import '../providers/fee_providers.dart';

class FeeDashboardScreen extends ConsumerWidget {
  const FeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummary = ref.watch(feeDashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fees')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(feeDashboardProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            asyncSummary.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => ErrorState(
                message: 'Failed to load fee dashboard',
                onRetry: () => ref.invalidate(feeDashboardProvider),
              ),
              data: (summary) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          label: 'Total Fees',
                          value: summary.totalFees,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryTile(label: 'Collected', value: summary.collected, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          label: 'Outstanding',
                          value: summary.outstanding,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryTile(label: 'Overdue', value: summary.overdue, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _NavCard(
              icon: Icons.receipt_long_outlined,
              label: 'Fee Structures',
              subtitle: 'Create and manage fee templates',
              onTap: () => context.push('/fees/structures'),
            ),
            _NavCard(
              icon: Icons.person_add_alt_outlined,
              label: 'Assign Fee',
              subtitle: 'Assign a fee structure to a student',
              onTap: () => context.push('/fees/assign'),
            ),
            _NavCard(
              icon: Icons.list_alt_outlined,
              label: 'All Student Fees',
              subtitle: 'View every assigned fee',
              onTap: () => context.push('/fees/all'),
            ),
            _NavCard(
              icon: Icons.payments_outlined,
              label: 'Payment History',
              subtitle: 'All recorded payments and receipts',
              onTap: () => context.push('/payments'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              formatCurrency(value),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
