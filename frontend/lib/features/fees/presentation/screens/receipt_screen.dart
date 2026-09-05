import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../../shared/widgets/currency_text.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../data/receipt_pdf_generator.dart';
import '../../domain/fee_models.dart';
import '../providers/fee_providers.dart';

final _receiptProvider = FutureProvider.family<Receipt, String>((ref, id) async {
  return ref.watch(feeRepositoryProvider).getReceipt(id);
});

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReceipt = ref.watch(_receiptProvider(receiptId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          asyncReceipt.maybeWhen(
            data: (receipt) => IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: () async {
                final doc = await buildReceiptPdf(receipt);
                await Printing.layoutPdf(onLayout: (_) => doc.save());
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          asyncReceipt.maybeWhen(
            data: (receipt) => IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () async {
                final doc = await buildReceiptPdf(receipt);
                await Printing.sharePdf(
                  bytes: await doc.save(),
                  filename: '${receipt.receiptNumber}.pdf',
                );
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncReceipt.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load receipt',
          onRetry: () => ref.invalidate(_receiptProvider(receiptId)),
        ),
        data: (receipt) => _ReceiptBody(receipt: receipt),
      ),
    );
  }
}

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(receipt.instituteName, style: Theme.of(context).textTheme.titleLarge),
              Text('Institute ID: ${receipt.instituteCode}', style: const TextStyle(color: Colors.grey)),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(receipt.receiptNumber, style: Theme.of(context).textTheme.titleMedium),
                  Text(dateFormat.format(receipt.paymentDate)),
                ],
              ),
              const Divider(height: 32),
              _row('Student', '${receipt.studentName} (${receipt.studentCode})'),
              if (receipt.parentName != null) _row('Parent/Guardian', receipt.parentName!),
              _row('Fee Structure', receipt.feeStructureName),
              _row('Installment', '#${receipt.installmentNumber}'),
              const SizedBox(height: 12),
              const Divider(),
              _row('Amount Paid', formatCurrency(receipt.amountPaid), bold: true),
              _row('Payment Method', receipt.paymentMethod.replaceAll('_', ' ')),
              if (receipt.transactionReference != null)
                _row('Transaction Ref', receipt.transactionReference!),
              const Divider(),
              _row('Previous Outstanding', formatCurrency(receipt.previousOutstanding)),
              _row('Remaining Outstanding', formatCurrency(receipt.remainingOutstanding)),
              const Divider(),
              _row('Received By', receipt.receivedByName),
              const SizedBox(height: 16),
              const Text(
                'This is a computer-generated receipt.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}
