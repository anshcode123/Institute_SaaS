import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/currency_text.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/fee_models.dart';
import '../providers/fee_providers.dart';
import '../widgets/fee_status_chip.dart';

class StudentFeeDetailScreen extends ConsumerWidget {
  const StudentFeeDetailScreen({super.key, required this.studentFeeId});

  final String studentFeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFee = ref.watch(studentFeeDetailProvider(studentFeeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Student Fee')),
      body: asyncFee.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load fee',
          onRetry: () => ref.invalidate(studentFeeDetailProvider(studentFeeId)),
        ),
        data: (fee) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (fee.student != null) ...[
              Text(fee.student!.fullName, style: Theme.of(context).textTheme.headlineSmall),
              Text(fee.student!.studentCode, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
            ],
            Text(fee.feeStructureName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            FeeStatusChip(status: fee.status),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Total Fee', formatCurrency(fee.totalAmount, currency: fee.currency)),
                    if (fee.discountAmount > 0)
                      _row('Discount', '- ${formatCurrency(fee.discountAmount, currency: fee.currency)}'),
                    _row('Final Fee', formatCurrency(fee.finalAmount, currency: fee.currency), bold: true),
                    const Divider(),
                    _row('Paid', formatCurrency(fee.paidAmount, currency: fee.currency), color: Colors.green),
                    _row(
                      'Outstanding',
                      formatCurrency(fee.outstandingAmount, currency: fee.currency),
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Installments', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final installment in fee.installments)
              _InstallmentTile(fee: fee, installment: installment),
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
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile({required this.fee, required this.installment});

  final StudentFee fee;
  final FeeInstallment installment;

  @override
  Widget build(BuildContext context) {
    final canPay = installment.status != 'PAID' && installment.status != 'CANCELLED';
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('${installment.installmentNumber}')),
        title: Text(formatCurrency(installment.amount, currency: fee.currency)),
        subtitle: Text(
          'Due ${DateFormat.yMMMd().format(installment.dueDate)}'
          '${installment.paidAmount > 0 ? ' • Paid ${formatCurrency(installment.paidAmount, currency: fee.currency)}' : ''}',
        ),
        trailing: canPay
            ? FilledButton(
                onPressed: () => context.push(
                  '/fees/${fee.id}/pay?installmentId=${installment.id}',
                ),
                child: const Text('Pay'),
              )
            : FeeStatusChip(status: installment.status),
      ),
    );
  }
}
