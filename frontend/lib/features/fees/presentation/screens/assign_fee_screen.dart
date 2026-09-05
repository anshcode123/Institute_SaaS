import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/currency_text.dart';
import '../../../students/domain/student_models.dart';
import '../../../students/presentation/providers/student_providers.dart';
import '../../domain/fee_models.dart';
import '../providers/fee_providers.dart';

enum _DiscountMode { none, fixed, percentage }

class AssignFeeScreen extends ConsumerStatefulWidget {
  const AssignFeeScreen({super.key, this.preselectedFeeStructureId, this.preselectedStudentId});

  final String? preselectedFeeStructureId;
  final String? preselectedStudentId;

  @override
  ConsumerState<AssignFeeScreen> createState() => _AssignFeeScreenState();
}

class _AssignFeeScreenState extends ConsumerState<AssignFeeScreen> {
  final _studentSearchController = TextEditingController();
  final _discountController = TextEditingController();
  List<Student> _studentResults = [];
  Student? _selectedStudent;
  FeeStructure? _selectedStructure;
  _DiscountMode _discountMode = _DiscountMode.none;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedStudentId != null) {
      _preselectStudent(widget.preselectedStudentId!);
    }
  }

  Future<void> _preselectStudent(String studentId) async {
    try {
      final student = await ref.read(studentRepositoryProvider).getById(studentId);
      if (mounted) setState(() => _selectedStudent = student);
    } catch (_) {
      // If the lookup fails, the field just stays empty for manual search.
    }
  }

  @override
  void dispose() {
    _studentSearchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _searchStudents(String query) async {
    final result = await ref.read(studentRepositoryProvider).list(query: query);
    setState(() => _studentResults = result.items);
  }

  double? get _finalPreview {
    if (_selectedStructure == null) return null;
    final total = _selectedStructure!.totalAmount;
    final discountInput = double.tryParse(_discountController.text) ?? 0;
    final discount = switch (_discountMode) {
      _DiscountMode.none => 0.0,
      _DiscountMode.fixed => discountInput,
      _DiscountMode.percentage => total * (discountInput / 100),
    };
    return (total - discount).clamp(0, total);
  }

  Future<void> _submit() async {
    if (_selectedStudent == null || _selectedStructure == null) {
      setState(() => _errorMessage = 'Select a student and a fee structure');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final discountInput = double.tryParse(_discountController.text);
      final studentFee = await ref.read(feeRepositoryProvider).assignFee(
            studentId: _selectedStudent!.id,
            feeStructureId: _selectedStructure!.id,
            discountAmount: _discountMode == _DiscountMode.fixed ? discountInput : null,
            discountPercentage: _discountMode == _DiscountMode.percentage ? discountInput : null,
          );
      if (mounted) context.pushReplacement('/fees/${studentFee.id}');
    } catch (e) {
      setState(() => _errorMessage = e is AppException ? e.message : 'Failed to assign fee');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncStructures = ref.watch(feeStructuresProvider('ACTIVE'));

    // Pre-select the structure once the list loads, if navigated here
    // from a fee structure's "Assign to Student" button.
    if (widget.preselectedFeeStructureId != null && _selectedStructure == null) {
      asyncStructures.whenData((structures) {
        final match = structures.where((s) => s.id == widget.preselectedFeeStructureId).firstOrNull;
        if (match != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedStructure = match);
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Fee')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Student', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _studentSearchController,
            decoration: const InputDecoration(
              hintText: 'Search student by name or code',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _searchStudents,
          ),
          if (_selectedStudent != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                label: Text('${_selectedStudent!.fullName} (${_selectedStudent!.studentCode})'),
                onDeleted: () => setState(() => _selectedStudent = null),
              ),
            )
          else if (_studentResults.isNotEmpty)
            SizedBox(
              height: 160,
              child: ListView.builder(
                itemCount: _studentResults.length,
                itemBuilder: (context, index) {
                  final s = _studentResults[index];
                  return ListTile(
                    dense: true,
                    title: Text(s.fullName),
                    subtitle: Text(s.studentCode),
                    onTap: () => setState(() {
                      _selectedStudent = s;
                      _studentResults = [];
                    }),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          Text('Fee Structure', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          asyncStructures.when(
            loading: () => const CircularProgressIndicator(),
            error: (err, _) => const Text('Failed to load fee structures'),
            data: (structures) => DropdownButtonFormField<FeeStructure>(
              initialValue: _selectedStructure,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              hint: const Text('Select fee structure'),
              items: structures
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.name} — ${formatCurrency(s.totalAmount, currency: s.currency)}'),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedStructure = value),
            ),
          ),
          const SizedBox(height: 20),
          Text('Discount (optional)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<_DiscountMode>(
            segments: const [
              ButtonSegment(value: _DiscountMode.none, label: Text('None')),
              ButtonSegment(value: _DiscountMode.fixed, label: Text('Fixed ₹')),
              ButtonSegment(value: _DiscountMode.percentage, label: Text('Percent %')),
            ],
            selected: {_discountMode},
            onSelectionChanged: (selection) => setState(() => _discountMode = selection.first),
          ),
          if (_discountMode != _DiscountMode.none) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _discountController,
              decoration: InputDecoration(
                labelText: _discountMode == _DiscountMode.fixed ? 'Discount Amount' : 'Discount Percentage',
                prefixText: _discountMode == _DiscountMode.fixed ? '₹ ' : null,
                suffixText: _discountMode == _DiscountMode.percentage ? '%' : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_finalPreview != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Final Payable Amount'),
                    Text(
                      formatCurrency(_finalPreview!, currency: _selectedStructure!.currency),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Assign Fee'),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
