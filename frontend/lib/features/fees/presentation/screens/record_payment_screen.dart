import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/currency_text.dart';
import '../../../../shared/widgets/error_state.dart';
import '../providers/fee_providers.dart';

const _paymentMethods = ['CASH', 'UPI', 'BANK_TRANSFER', 'CARD', 'OTHER'];

class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({super.key, required this.studentFeeId, required this.installmentId});

  final String studentFeeId;
  final String installmentId;

  @override
  ConsumerState<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionRefController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'CASH';
  DateTime _paymentDate = DateTime.now();
  bool _isSaving = false;
  String? _errorMessage;
  bool _prefilled = false;

  @override
  void dispose() {
    _amountController.dispose();
    _transactionRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final fee = ref.read(studentFeeDetailProvider(widget.studentFeeId)).value!;
      final payment = await ref.read(feeRepositoryProvider).recordPayment(
            studentId: fee.studentId,
            studentFeeId: widget.studentFeeId,
            installmentId: widget.installmentId,
            amount: double.parse(_amountController.text),
            paymentMethod: _paymentMethod,
            transactionReference: _transactionRefController.text.trim(),
            paymentDate: _paymentDate,
            notes: _notesController.text.trim(),
          );
      ref.invalidate(studentFeeDetailProvider(widget.studentFeeId));
      ref.invalidate(feeDashboardProvider);
      if (mounted && payment.receiptId != null) {
        context.pushReplacement('/receipts/${payment.receiptId}');
      } else if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() => _errorMessage = e is AppException ? e.message : 'Failed to record payment');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncFee = ref.watch(studentFeeDetailProvider(widget.studentFeeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: asyncFee.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load fee details',
          onRetry: () => ref.invalidate(studentFeeDetailProvider(widget.studentFeeId)),
        ),
        data: (fee) {
          final installment = fee.installments.firstWhere((i) => i.id == widget.installmentId);
          if (!_prefilled) {
            _amountController.text = installment.remaining.toStringAsFixed(2);
            _prefilled = true;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Installment ${installment.installmentNumber}'),
                        const SizedBox(height: 4),
                        Text(
                          'Remaining: ${formatCurrency(installment.remaining, currency: fee.currency)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter a valid amount';
                    if (n > installment.remaining + 0.01) return 'Cannot exceed remaining amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                  items: _paymentMethods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m.replaceAll('_', ' '))))
                      .toList(),
                  onChanged: (v) => setState(() => _paymentMethod = v ?? 'CASH'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _transactionRefController,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Reference (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Payment Date'),
                  subtitle: Text(DateFormat.yMMMd().format(_paymentDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Record Payment'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
