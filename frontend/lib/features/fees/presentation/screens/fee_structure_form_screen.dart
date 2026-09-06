import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/fee_models.dart';
import '../providers/fee_providers.dart';

class _InstallmentRow {
  final amountController = TextEditingController();
  DateTime? dueDate;
}

class _SubjectFeeRow {
  final subjectController = TextEditingController();
  final amountController = TextEditingController();
}

class _MonthlyFeeGroup {
  final nameController = TextEditingController();
  final educationLevelController = TextEditingController();
  final combinedAmountController = TextEditingController();
  final List<_SubjectFeeRow> subjects = [];
  String pricingType = 'SUBJECT_WISE';

  void dispose() {
    nameController.dispose();
    educationLevelController.dispose();
    combinedAmountController.dispose();
    for (final subject in subjects) {
      subject.subjectController.dispose();
      subject.amountController.dispose();
    }
  }

  double get total => pricingType == 'COMBINED'
      ? double.tryParse(combinedAmountController.text) ?? 0
      : subjects.fold<double>(
          0,
          (sum, subject) =>
              sum + (double.tryParse(subject.amountController.text) ?? 0),
        );
}

/// Fee structures are create-only beyond name/description/status.
class FeeStructureFormScreen extends ConsumerStatefulWidget {
  const FeeStructureFormScreen({super.key});

  @override
  ConsumerState<FeeStructureFormScreen> createState() =>
      _FeeStructureFormScreenState();
}

class _FeeStructureFormScreenState
    extends ConsumerState<FeeStructureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _courseTotalController = TextEditingController();
  final _feeStartDateController = TextEditingController();
  final _dueDayController = TextEditingController();
  final _lateFeeController = TextEditingController();
  final _gracePeriodController = TextEditingController();
  final List<_MonthlyFeeGroup> _monthlyGroups = [];
  final List<_InstallmentRow> _installments = [];

  String _feeType = 'MONTHLY_FEE';
  String _coursePaymentMode = 'FULL';
  String _lateFeeType = 'FIXED';
  DateTime? _feeStartDate;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _addMonthlyGroup();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _courseTotalController.dispose();
    _feeStartDateController.dispose();
    _dueDayController.dispose();
    _lateFeeController.dispose();
    _gracePeriodController.dispose();
    for (final group in _monthlyGroups) {
      group.dispose();
    }
    for (final row in _installments) {
      row.amountController.dispose();
    }
    super.dispose();
  }

  double get _monthlyTotal =>
      _monthlyGroups.fold<double>(0, (sum, group) => sum + group.total);

  double get _installmentsSum => _installments.fold<double>(
        0,
        (sum, row) => sum + (double.tryParse(row.amountController.text) ?? 0),
      );

  void _addMonthlyGroup() =>
      setState(() => _monthlyGroups.add(_MonthlyFeeGroup()));

  void _removeMonthlyGroup(int index) {
    final group = _monthlyGroups.removeAt(index);
    group.dispose();
    setState(() {});
  }

  void _addSubject(_MonthlyFeeGroup group) {
    setState(() => group.subjects.add(_SubjectFeeRow()));
  }

  void _removeSubject(_MonthlyFeeGroup group, int index) {
    final subject = group.subjects.removeAt(index);
    subject.subjectController.dispose();
    subject.amountController.dispose();
    setState(() {});
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    DateTime? initialDate,
    DateTime? firstDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      controller.text = DateFormat.yMMMd().format(picked);
      if (identical(controller, _feeStartDateController)) {
        _feeStartDate = picked;
      }
      setState(() {});
    }
  }

  Future<void> _pickDueDate(_InstallmentRow row) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: row.dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => row.dueDate = picked);
    }
  }

  String? _positiveAmount(String? value) {
    final amount = double.tryParse(value ?? '');
    return amount == null || amount <= 0 ? 'Enter a valid amount' : null;
  }

  String? _validateMonthly() {
    if (_monthlyGroups.isEmpty) {
      return 'Add at least one fee group';
    }
    for (var groupIndex = 0; groupIndex < _monthlyGroups.length; groupIndex++) {
      final group = _monthlyGroups[groupIndex];
      if (group.nameController.text.trim().isEmpty) {
        return 'Enter a name for fee group ${groupIndex + 1}';
      }
      if (group.educationLevelController.text.trim().isEmpty) {
        return 'Enter the applicable class or education level for fee group ${groupIndex + 1}';
      }
      if (group.pricingType == 'COMBINED') {
        if (group.total <= 0) {
          return 'Enter a valid combined amount for fee group ${groupIndex + 1}';
        }
        continue;
      }
      if (group.subjects.isEmpty) {
        return 'Add at least one subject rule to fee group ${groupIndex + 1}';
      }
      final names = <String>{};
      for (final subject in group.subjects) {
        final name = subject.subjectController.text.trim().toLowerCase();
        if (name.isEmpty) {
          return 'Select a subject for fee group ${groupIndex + 1}';
        }
        if (!names.add(name)) {
          return 'A subject can only appear once in the same fee group';
        }
        if ((double.tryParse(subject.amountController.text) ?? 0) <= 0) {
          return 'Enter a valid monthly amount for $name';
        }
      }
    }
    if (_monthlyTotal <= 0) {
      return 'Enter at least one positive monthly amount';
    }
    if (_feeStartDate == null) {
      return 'Select a fee start date';
    }
    final dueDay = int.tryParse(_dueDayController.text);
    if (dueDay == null || dueDay < 1 || dueDay > 31) {
      return 'Enter a due day from 1 to 31';
    }
    final lateFee = double.tryParse(_lateFeeController.text);
    if (lateFee == null || lateFee < 0) return 'Enter a valid late fee';
    final gracePeriod = int.tryParse(_gracePeriodController.text);
    if (gracePeriod == null || gracePeriod < 0) {
      return 'Enter a valid grace period';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_feeType == 'MONTHLY_FEE') {
      final monthlyError = _validateMonthly();
      if (monthlyError != null) {
        setState(() => _errorMessage = monthlyError);
        return;
      }
    } else {
      final total = double.tryParse(_courseTotalController.text) ?? 0;
      if ((_installmentsSum - total).abs() > 0.01) {
        setState(
          () =>
              _errorMessage = 'EMI amounts must equal the final payable amount',
        );
        return;
      }
      if (_installments.any((row) => row.dueDate == null)) {
        setState(() => _errorMessage = 'Every payment needs a due date');
        return;
      }
      if (_coursePaymentMode == 'EMI' && _installments.length < 2) {
        setState(() => _errorMessage = 'EMI requires at least two payments');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final total = _feeType == 'MONTHLY_FEE'
          ? _monthlyTotal
          : double.parse(_courseTotalController.text);
      await ref.read(feeRepositoryProvider).createFeeStructure(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            totalAmount: total,
            feeType: _feeType,
            coursePaymentMode:
                _feeType == 'COURSE_FEE' ? _coursePaymentMode : null,
            installments: _feeType == 'COURSE_FEE'
                ? [
                    for (var i = 0; i < _installments.length; i++)
                      FeeStructureInstallmentTemplate(
                        installmentNumber: i + 1,
                        amount: double.parse(
                          _installments[i].amountController.text,
                        ),
                        dueDate: _installments[i].dueDate!,
                      ),
                  ]
                : const [],
          );
      ref.invalidate(feeStructuresProvider(null));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage =
              e is AppException ? e.message : 'Failed to create fee structure',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMonthly = _feeType == 'MONTHLY_FEE';
    return Scaffold(
      appBar: AppBar(title: const Text('Create Fee Structure')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Fee Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Text('Fee Type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'MONTHLY_FEE', label: Text('Monthly Fee')),
                ButtonSegment(value: 'COURSE_FEE', label: Text('Course Fee')),
              ],
              selected: {_feeType},
              onSelectionChanged: (selection) => setState(() {
                _feeType = selection.first;
                if (_feeType == 'COURSE_FEE' && _installments.isEmpty) {
                  _installments.add(_InstallmentRow());
                }
              }),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            if (isMonthly)
              _buildMonthlyContent(context)
            else
              _buildCourseContent(context),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Fee Structure'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fee Groups', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (var i = 0; i < _monthlyGroups.length; i++)
          _buildMonthlyGroup(context, i),
        OutlinedButton.icon(
          onPressed: _addMonthlyGroup,
          icon: const Icon(Icons.add),
          label: const Text('Add Fee Group'),
        ),
        const SizedBox(height: 20),
        Text('Fee Rules', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextFormField(
          controller: _feeStartDateController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Fee Start Date',
            border: OutlineInputBorder(),
          ),
          onTap: () => _pickDate(controller: _feeStartDateController),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _dueDayController,
          decoration: const InputDecoration(
            labelText: 'Due Day / Due Date',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'FIXED', label: Text('Fixed Amount')),
            ButtonSegment(value: 'PERCENTAGE', label: Text('Percentage')),
          ],
          selected: {_lateFeeType},
          onSelectionChanged: (selection) =>
              setState(() => _lateFeeType = selection.first),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _lateFeeController,
          decoration: InputDecoration(
            labelText: _lateFeeType == 'FIXED'
                ? 'Late Fee Amount'
                : 'Late Fee Percentage',
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _gracePeriodController,
          decoration: const InputDecoration(
            labelText: 'Grace Period (days)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildMonthlyGroup(BuildContext context, int index) {
    final group = _monthlyGroups[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fee Group ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_monthlyGroups.length > 1)
                  IconButton(
                    tooltip: 'Remove fee group',
                    onPressed: () => _removeMonthlyGroup(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: group.nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: group.educationLevelController,
              decoration: const InputDecoration(
                labelText: 'Applicable Class / Education Level',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text('Pricing Type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'SUBJECT_WISE',
                  label: Text('Subject-wise'),
                ),
                ButtonSegment(value: 'COMBINED', label: Text('Combined')),
              ],
              selected: {group.pricingType},
              onSelectionChanged: (selection) =>
                  setState(() => group.pricingType = selection.first),
            ),
            const SizedBox(height: 12),
            if (group.pricingType == 'SUBJECT_WISE') ...[
              for (var subjectIndex = 0;
                  subjectIndex < group.subjects.length;
                  subjectIndex++)
                _buildSubjectRow(context, group, subjectIndex),
              TextButton.icon(
                onPressed: () => _addSubject(group),
                icon: const Icon(Icons.add),
                label: const Text('Add Subject'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Monthly Total: ₹${group.total.toStringAsFixed(2)}',
                ),
              ),
            ] else ...[
              TextFormField(
                controller: group.combinedAmountController,
                decoration: const InputDecoration(
                  labelText: 'Combined Monthly Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectRow(
    BuildContext context,
    _MonthlyFeeGroup group,
    int index,
  ) {
    final subject = group.subjects[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: subject.subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: subject.amountController,
              decoration: const InputDecoration(
                labelText: 'Monthly Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          IconButton(
            tooltip: 'Remove subject',
            onPressed: () => _removeSubject(group, index),
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseContent(BuildContext context) {
    final total = double.tryParse(_courseTotalController.text) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Course',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _courseTotalController,
          decoration: const InputDecoration(
            labelText: 'Total Course Fee',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          validator: _positiveAmount,
        ),
        const SizedBox(height: 12),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Discount (optional)',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
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
                _installments.removeLast().amountController.dispose();
              }
            } else if (_installments.isEmpty) {
              _installments.add(_InstallmentRow());
            }
          }),
        ),
        const SizedBox(height: 12),
        if (_coursePaymentMode == 'FULL')
          Text('Final Payable: ₹${total.toStringAsFixed(2)}')
        else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EMI Schedule',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _installments.add(_InstallmentRow())),
                icon: const Icon(Icons.add),
                label: const Text('Add EMI'),
              ),
            ],
          ),
          for (var i = 0; i < _installments.length; i++)
            _buildInstallmentRow(i),
          Text('Total EMI Amount: ₹${_installmentsSum.toStringAsFixed(2)}'),
          Text('Final Payable: ₹${total.toStringAsFixed(2)}'),
          Text('Difference: ₹${(total - _installmentsSum).toStringAsFixed(2)}'),
        ],
      ],
    );
  }

  Widget _buildInstallmentRow(int index) {
    final row = _installments[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text('EMI ${index + 1}')),
          Expanded(
            child: TextFormField(
              controller: row.amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              validator: _positiveAmount,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _pickDueDate(row),
              child: Text(
                row.dueDate == null
                    ? 'Due Date'
                    : DateFormat.yMMMd().format(row.dueDate!),
              ),
            ),
          ),
          if (_installments.length > 2)
            IconButton(
              onPressed: () {
                final removed = _installments.removeAt(index);
                removed.amountController.dispose();
                setState(() {});
              },
              icon: const Icon(Icons.remove_circle_outline),
            ),
        ],
      ),
    );
  }
}
