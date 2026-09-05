import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/currency_text.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/fee_models.dart';
import '../providers/fee_providers.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key, this.studentId});

  final String? studentId;

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  final int _page = 1;
  bool _loading = true;
  String? _error;
  List<Payment> _items = [];

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
          .listPayments(studentId: widget.studentId, page: _page);
      setState(() {
        _items = result.items;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e is AppException ? e.message : 'Failed to load payments');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return const EmptyState(message: 'No payments recorded yet.', icon: Icons.payments_outlined);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final payment = _items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              onTap: payment.receiptId != null
                  ? () => context.push('/receipts/${payment.receiptId}')
                  : null,
              title: Text(payment.student?.fullName ?? 'Unknown student'),
              subtitle: Text(
                '${payment.receiptNumber ?? '-'} • ${payment.paymentMethod} • '
                '${DateFormat.yMMMd().format(payment.paymentDate)}\n'
                'Received by ${payment.receivedByName ?? '-'}',
              ),
              isThreeLine: true,
              trailing: Text(
                formatCurrency(payment.amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
