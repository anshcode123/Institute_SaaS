import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/fee_models.dart';
import '../providers/fee_providers.dart';

enum _FeeType { monthly, course }

enum _Pricing { combined, subjectWise }

class _Emi {
  final amount = TextEditingController();
  DateTime? dueDate;
}

class _Group {
  final name = TextEditingController();
  final level = TextEditingController();
  final amount = TextEditingController();
  _Pricing pricing = _Pricing.combined;
  final List<_SubjectPrice> subjects = [_SubjectPrice()];
}

class _SubjectPrice {
  final id = TextEditingController();
  final amount = TextEditingController();
}

class FeeStructureFormScreen extends ConsumerStatefulWidget {
  const FeeStructureFormScreen({super.key});
  @override
  ConsumerState<FeeStructureFormScreen> createState() =>
      _FeeStructureFormScreenState();
}

class _FeeStructureFormScreenState
    extends ConsumerState<FeeStructureFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _courseId = TextEditingController();
  final _total = TextEditingController();
  final _dueDay = TextEditingController(text: '5');
  final _lateFee = TextEditingController(text: '0');
  _FeeType _type = _FeeType.monthly;
  bool _emi = false;
  bool _saving = false;
  String? _error;
  final _groups = [_Group()];
  final _emis = [_Emi()];
  @override
  void dispose() {
    for (final c in [
      _name,
      _description,
      _courseId,
      _total,
      _dueDay,
      _lateFee
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _emiTotal() => _emis.fold(
      0, (sum, row) => sum + (double.tryParse(row.amount.text) ?? 0));
  Future<void> _date(void Function(DateTime) set) async {
    final value = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (value != null) setState(() => set(value));
  }

  Future<void> _submit() async {
    if (_form.currentState?.validate() != true) return;
    if (_type == _FeeType.course &&
        _emi &&
        (_emis.any((row) => row.dueDate == null) ||
            (_emiTotal() - (double.tryParse(_total.text) ?? 0)).abs() > .01)) {
      setState(() => _error =
          'Every EMI needs a due date and EMI total must equal final payable.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(feeRepositoryProvider).createFeeStructure(
            name: _name.text.trim(),
            description: _description.text.trim(),
            feeType: _type == _FeeType.monthly ? 'MONTHLY' : 'COURSE',
            totalAmount:
                _type == _FeeType.course ? double.parse(_total.text) : null,
            courseId: _type == _FeeType.course ? _courseId.text.trim() : null,
            coursePaymentMode:
                _type == _FeeType.course ? (_emi ? 'EMI' : 'FULL') : null,
            monthlyDueDay:
                _type == _FeeType.monthly ? int.parse(_dueDay.text) : null,
            lateFee:
                _type == _FeeType.monthly ? double.parse(_lateFee.text) : null,
            monthlyGroups: _type == _FeeType.monthly
                ? _groups
                    .map((group) => MonthlyFeeGroup(
                        name: group.name.text.trim(),
                        applicableLevel: group.level.text.trim(),
                        pricingType: group.pricing == _Pricing.combined
                            ? 'COMBINED'
                            : 'SUBJECT_WISE',
                        combinedAmount: group.pricing == _Pricing.combined
                            ? double.parse(group.amount.text)
                            : null,
                        subjects: group.pricing == _Pricing.subjectWise
                            ? group.subjects
                                .map((row) => MonthlyFeeGroupSubject(
                                    subjectId: row.id.text.trim(),
                                    monthlyAmount:
                                        double.parse(row.amount.text)))
                                .toList()
                            : const []))
                    .toList()
                : const [],
            installments: _type == _FeeType.course && _emi
                ? [
                    for (var i = 0; i < _emis.length; i++)
                      FeeStructureInstallmentTemplate(
                          installmentNumber: i + 1,
                          amount: double.parse(_emis[i].amount.text),
                          dueDate: _emis[i].dueDate!)
                  ]
                : const [],
          );
      ref.invalidate(feeStructuresProvider(null));
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error =
          e is AppException ? e.message : 'Failed to create fee structure');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Create Fee Structure')),
      body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            SegmentedButton<_FeeType>(segments: const [
              ButtonSegment(
                  value: _FeeType.monthly, label: Text('Monthly Fee')),
              ButtonSegment(value: _FeeType.course, label: Text('Course Fee'))
            ], selected: {
              _type
            }, onSelectionChanged: (v) => setState(() => _type = v.first)),
            const SizedBox(height: 16),
            TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Fee name', border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            if (_type == _FeeType.monthly) ...[_monthly()] else ...[_course()],
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Creating...' : 'Create Fee Structure'))
          ])));
  Widget _monthly() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextFormField(
            controller: _dueDay,
            decoration: const InputDecoration(
                labelText: 'Due Day (1–31)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (v) => ((int.tryParse(v ?? '') ?? 0) < 1 ||
                    (int.tryParse(v ?? '') ?? 0) > 31)
                ? 'Enter 1–31'
                : null),
        const SizedBox(height: 12),
        TextFormField(
            controller: _lateFee,
            decoration: const InputDecoration(
                labelText: 'Late Fee',
                prefixText: '₹ ',
                border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) =>
                (double.tryParse(v ?? '') ?? -1) < 0 ? 'Invalid amount' : null),
        const SizedBox(height: 16),
        Text('Fee Groups', style: Theme.of(context).textTheme.titleMedium),
        for (final group in _groups) _group(group),
        TextButton.icon(
            onPressed: () => setState(() => _groups.add(_Group())),
            icon: const Icon(Icons.add),
            label: const Text('Add Fee Group'))
      ]);
  Widget _group(_Group group) => Card(
      child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            TextFormField(
                controller: group.name,
                decoration: const InputDecoration(
                    labelText: 'Group name', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 8),
            TextFormField(
                controller: group.level,
                decoration: const InputDecoration(
                    labelText: 'Applicable class / education level',
                    border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 8),
            DropdownButtonFormField<_Pricing>(
                initialValue: group.pricing,
                items: const [
                  DropdownMenuItem(
                      value: _Pricing.combined, child: Text('Combined')),
                  DropdownMenuItem(
                      value: _Pricing.subjectWise, child: Text('Subject-wise'))
                ],
                onChanged: (v) => setState(() => group.pricing = v!),
                decoration: const InputDecoration(
                    labelText: 'Pricing type', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            if (group.pricing == _Pricing.combined)
              TextFormField(
                  controller: group.amount,
                  decoration: const InputDecoration(
                      labelText: 'Monthly amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder()),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null)
            else ...[
              for (final subject in group.subjects)
                Row(children: [
                  Expanded(
                      child: TextFormField(
                          controller: subject.id,
                          decoration: const InputDecoration(
                              labelText: 'Existing Subject ID'),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextFormField(
                          controller: subject.amount,
                          decoration:
                              const InputDecoration(labelText: 'Monthly ₹'),
                          keyboardType: TextInputType.number,
                          validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                              ? 'Required'
                              : null))
                ]),
              TextButton(
                  onPressed: () =>
                      setState(() => group.subjects.add(_SubjectPrice())),
                  child: const Text('Add subject'))
            ]
          ])));
  Widget _course() => Column(children: [
        TextFormField(
            controller: _courseId,
            decoration: const InputDecoration(
                labelText: 'Existing Course ID', border: OutlineInputBorder()),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        TextFormField(
            controller: _total,
            decoration: const InputDecoration(
                labelText: 'Total course fee',
                prefixText: '₹ ',
                border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (v) =>
                (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null),
        SwitchListTile(
          title: const Text('EMI payment plan'),
          subtitle:
              Text(_emi ? 'Custom EMI amounts and dates' : 'Full payment'),
          value: _emi,
          onChanged: (v) => setState(() => _emi = v),
        ),
        if (_emi) ...[
          for (final row in _emis)
            Row(children: [
              Expanded(
                  child: TextFormField(
                      controller: row.amount,
                      decoration:
                          const InputDecoration(labelText: 'EMI amount'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                          ? 'Required'
                          : null)),
              TextButton(
                  onPressed: () => _date((d) => row.dueDate = d),
                  child: Text(row.dueDate == null
                      ? 'Due date'
                      : DateFormat.yMMMd().format(row.dueDate!)))
            ]),
          Text('EMI total: ₹${_emiTotal().toStringAsFixed(2)}'),
          TextButton.icon(
              onPressed: () => setState(() => _emis.add(_Emi())),
              icon: const Icon(Icons.add),
              label: const Text('Add EMI'))
        ]
      ]);
}
