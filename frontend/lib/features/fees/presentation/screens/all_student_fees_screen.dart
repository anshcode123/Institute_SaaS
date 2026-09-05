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
  ConsumerState<AllStudentFeesScreen> createState() => _AllStudentFeesScreenState();
}

class _AllStudentFeesScreenState extends ConsumerState<AllStudentFeesScreen> {
  String? _statusFilter;
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
      final result = await ref.read(feeRepositoryProvider).listStudentFees(status: _statusFilter);
      setState(() {
        _items = result.items;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e is AppException ? e.message : 'Failed to load fees');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              PopupMenuItem(value: 'PARTIALLY_PAID', child: Text('Partially Paid')),
              PopupMenuItem(value: 'PAID', child: Text('Paid')),
              PopupMenuItem(value: 'OVERDUE', child: Text('Overdue')),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return const EmptyState(message: 'No fees assigned yet.', icon: Icons.receipt_long_outlined);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final fee = _items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              onTap: () => context.push('/fees/${fee.id}'),
              title: Text(fee.student?.fullName ?? 'Unknown student'),
              subtitle: Text(
                '${fee.feeStructureName} • Outstanding: ${formatCurrency(fee.outstandingAmount, currency: fee.currency)}',
              ),
              trailing: FeeStatusChip(status: fee.status),
            ),
          );
        },
      ),
    );
  }
}
