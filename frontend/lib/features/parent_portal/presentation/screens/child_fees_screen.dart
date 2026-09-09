import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/currency_text.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../fees/domain/fee_models.dart';
import '../../../fees/presentation/widgets/fee_status_chip.dart';
import '../providers/parent_portal_providers.dart';

class ChildFeesScreen extends ConsumerWidget {
  const ChildFeesScreen({super.key, required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFees = ref.watch(_feesProvider(studentId));
    return Scaffold(
      appBar: AppBar(title: const Text('Fees')),
      body: asyncFees.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
            message: 'Failed to load fees',
            onRetry: () => ref.invalidate(_feesProvider(studentId))),
        data: (result) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(
                        'Total Fee', formatCurrency(result.summary.finalAmount),
                        bold: true),
                    _row('Paid', formatCurrency(result.summary.paidAmount),
                        color: Colors.green),
                    _row('Outstanding',
                        formatCurrency(result.summary.outstandingAmount),
                        color: Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final fee in result.fees)
              Card(
                child: ExpansionTile(
                  title: Text(fee.feeStructureName),
                  subtitle: Text(
                      '${formatCurrency(fee.paidAmount)} of ${formatCurrency(fee.finalAmount)}'),
                  trailing: FeeStatusChip(status: fee.status),
                  children: [
                    for (final installment in fee.installments)
                      ListTile(
                        title: Text(
                            'Installment ${installment.installmentNumber}'),
                        subtitle: Text(formatCurrency(installment.amount)),
                        trailing: FeeStatusChip(status: installment.status),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color))
        ],
      ),
    );
  }
}

final _feesProvider = FutureProvider.family<StudentFeesResult, String>(
    (ref, String studentId) async {
  return ref.watch(parentPortalRepositoryProvider).getChildFees(studentId);
});
