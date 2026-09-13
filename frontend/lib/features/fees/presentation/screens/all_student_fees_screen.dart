import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/currency_text.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/fee_models.dart';
import '../providers/fee_providers.dart';
import '../widgets/fee_status_chip.dart';

class AllStudentFeesScreen extends ConsumerStatefulWidget {
  const AllStudentFeesScreen({super.key});

  @override
  ConsumerState<AllStudentFeesScreen> createState() =>
      _AllStudentFeesScreenState();
}

class _AllStudentFeesScreenState extends ConsumerState<AllStudentFeesScreen> {
  String? _statusFilter;
  String _searchQuery = '';
  bool _loading = true;
  String? _error;
  List<StudentFee> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(feeRepositoryProvider)
          .listStudentFees(status: _statusFilter);
      setState(() {
        _items = result.items;
        _error = null;
      });
    } catch (e) {
      setState(
          () => _error = e is AppException ? e.message : 'Failed to load fees');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<StudentFee> get _filteredItems {
    if (_searchQuery.trim().isEmpty) return _items;
    final q = _searchQuery.trim().toLowerCase();
    return _items.where((fee) {
      final name = (fee.student?.fullName ?? '').toLowerCase();
      final code = (fee.student?.studentCode ?? '').toLowerCase();
      final structure = fee.feeStructureName.toLowerCase();
      return name.contains(q) || code.contains(q) || structure.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayedItems = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Student Fees'),
        actions: [
          PopupMenuButton<String?>(
            onSelected: (value) {
              setState(() => _statusFilter = value);
              _load();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: null, child: Text('All statuses')),
              PopupMenuItem(value: 'PENDING', child: Text('Pending')),
              PopupMenuItem(
                  value: 'PARTIALLY_PAID', child: Text('Partially Paid')),
              PopupMenuItem(value: 'PAID', child: Text('Paid')),
              PopupMenuItem(value: 'OVERDUE', child: Text('Overdue')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by student name or fee...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(child: _buildBody(displayedItems)),
        ],
      ),
    );
  }

  Widget _buildBody(List<StudentFee> displayedItems) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);
    if (displayedItems.isEmpty) {
      return const EmptyState(
          message: 'No fees found.', icon: Icons.receipt_long_outlined);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: displayedItems.length,
        itemBuilder: (context, index) {
          final fee = displayedItems[index];
          final dueInfo =
              fee.dueStatusText != null && fee.dueStatusText!.isNotEmpty
                  ? ' • ${fee.dueStatusText}'
                  : '';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              onTap: () => context.push('/fees/${fee.id}'),
              title: Text(fee.student?.fullName ?? 'Unknown student'),
              subtitle: Text(
                '${fee.feeStructureName}$dueInfo\nOutstanding: ${formatCurrency(fee.outstandingAmount, currency: fee.currency)}',
              ),
              isThreeLine: true,
              trailing: FeeStatusChip(status: fee.status),
            ),
          );
        },
      ),
    );
  }
}
