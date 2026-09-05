import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/fee_models.dart';
import '../providers/fee_providers.dart';

class _InstallmentRow {
  final _amountController = TextEditingController();
  DateTime? dueDate;
}

/// Create-only (fee structures aren't editable beyond name/description/
/// status once created - see backend comment on updateFeeStructure - so
/// there's no "editingId" mode here, unlike the other feature forms).
class FeeStructureFormScreen extends ConsumerStatefulWidget {
  const FeeStructureFormScreen({super.key});

  @override
  ConsumerState<FeeStructureFormScreen> createState() => _FeeStructureFormScreenState();
}

class _FeeStructureFormScreenState extends ConsumerState<FeeStructureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final List<_InstallmentRow> _installments = [_InstallmentRow()];
  String _feeType = 'MONTHLY';
  String _coursePaymentMode = 'FULL';

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _totalAmountController.dispose();
    for (final row in _installments) {
      row._amountController.dispose();
    }
    super.dispose();
  }

  double get _installmentsSum => _installments.fold(
        0,
        (sum, row) => sum + (double.tryParse(row._amountController.text) ?? 0),
      );

  Future<void> _pickDueDate(_InstallmentRow row) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: row.dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => row.dueDate = picked);
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    final total = double.tryParse(_totalAmountController.text) ?? 0;
    if ((_installmentsSum - total).abs() > 0.01) {
      setState(() => _errorMessage =
          'Installments must sum to the total amount (currently ${_installmentsSum.toStringAsFixed(2)})');
      return;
    }
    if (_installments.any((r) => r.dueDate == null)) {
      setState(() => _errorMessage = 'Every installment needs a due date');
      return;
    }
    if (_feeType == 'MONTHLY' && _installments.length != 1) {
      setState(() => _errorMessage = 'Monthly fees use one monthly payment schedule');
      return;
    }
    if (_feeType == 'COURSE' && _coursePaymentMode == 'EMI' && _installments.length < 2) {
      setState(() => _errorMessage = 'EMI requires at least two installments');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(feeRepositoryProvider).createFeeStructure(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            totalAmount: total,
            feeType: _feeType,
            coursePaymentMode: _feeType == 'COURSE' ? _coursePaymentMode : null,
            installments: [
              for (var i = 0; i < _installments.length; i++)
                FeeStructureInstallmentTemplate(
                  installmentNumber: i + 1,
                  amount: double.parse(_installments[i]._amountController.text),
                  dueDate: _installments[i].dueDate!,
                ),
            ],
          );
      ref.invalidate(feeStructuresProvider(null));
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _errorMessage = e is AppException ? e.message : 'Failed to create fee structure');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Fee Structure')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name (e.g. NEET 2026)', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Text('Fee Type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'MONTHLY', label: Text('Monthly Fee')),
                ButtonSegment(value: 'COURSE', label: Text('Course Fee')),
              ],
              selected: {_feeType},
              onSelectionChanged: (selection) => setState(() {
                _feeType = selection.first;
                if (_feeType == 'MONTHLY') {
                  while (_installments.length > 1) {
                    _installments.removeLast()._amountController.dispose();
                  }
                }
              }),
            ),
            if (_feeType == 'COURSE') ...[
              const SizedBox(height: 12),
              Text('Payment Plan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'FULL', label: Text('Full Payment')),
                  ButtonSegment(value: 'EMI', label: Text('EMI')),
                ],
                selected: {_coursePaymentMode},
                onSelectionChanged: (selection) => setState(() {
                  _coursePaymentMode = selection.first;
                  if (_coursePaymentMode == 'FULL') {
                    while (_installments.length > 1) {
                      _installments.removeLast()._amountController.dispose();
                    }
                  }
                }),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalAmountController,
              decoration: const InputDecoration(labelText: 'Total Amount', prefixText: '₹ ', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                return (n == null || n <= 0) ? 'Enter a valid amount' : null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Installments', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  onPressed: _feeType == 'MONTHLY' || _coursePaymentMode == 'FULL'
                      ? null
                      : () => setState(() => _installments.add(_InstallmentRow())),
                ),
              ],
            ),
            for (var i = 0; i < _installments.length; i++) _buildInstallmentRow(i),
            const SizedBox(height: 8),
            Text(
              'Sum: ${_installmentsSum.toStringAsFixed(2)} / ${(double.tryParse(_totalAmountController.text) ?? 0).toStringAsFixed(2)}',
              style: TextStyle(
                color: (_installmentsSum - (double.tryParse(_totalAmountController.text) ?? 0)).abs() < 0.01
                    ? Colors.green
                    : Colors.orange,
              ),
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
                  : const Text('Create Fee Structure'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentRow(int index) {
    final row = _installments[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('${index + 1}.')),
          Expanded(
            child: TextFormField(
              controller: row._amountController,
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ', isDense: true),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _pickDueDate(row),
              child: Text(row.dueDate != null ? DateFormat.yMMMd().format(row.dueDate!) : 'Due date'),
            ),
          ),
          if (_installments.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => setState(() => _installments.removeAt(index)),
            ),
        ],
      ),
    );
  }
}
