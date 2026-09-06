import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/currency_text.dart';
import '../../../../shared/widgets/error_state.dart';
import '../providers/fee_providers.dart';
import '../widgets/fee_status_chip.dart';

class FeeStructureDetailScreen extends ConsumerWidget {
  const FeeStructureDetailScreen({super.key, required this.structureId});

  final String structureId;

  Future<void> _toggleStatus(BuildContext context, WidgetRef ref, String currentStatus) async {
    final newStatus = currentStatus == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    await ref.read(feeRepositoryProvider).updateFeeStructure(structureId, {'status': newStatus});
    ref.invalidate(feeStructureDetailProvider(structureId));
    ref.invalidate(feeStructuresProvider(null));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStructure = ref.watch(feeStructureDetailProvider(structureId));

    return Scaffold(
      appBar: AppBar(title: const Text('Fee Structure')),
      body: asyncStructure.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load fee structure',
          onRetry: () => ref.invalidate(feeStructureDetailProvider(structureId)),
        ),
        data: (structure) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(structure.name, style: Theme.of(context).textTheme.headlineSmall),
            if (structure.description != null) ...[
              const SizedBox(height: 4),
              Text(structure.description!),
            ],
            const SizedBox(height: 8),
            FeeStatusChip(status: structure.status),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount'),
                    Text(
                      formatCurrency(structure.totalAmount, currency: structure.currency),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Installments', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final installment in structure.installments)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${installment.installmentNumber}')),
                  title: Text(formatCurrency(installment.amount, currency: structure.currency)),
                  subtitle: Text('Due ${DateFormat.yMMMd().format(installment.dueDate)}'),
                ),
              ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: Icon(structure.status == 'ACTIVE' ? Icons.pause_circle_outline : Icons.play_circle_outline),
              label: Text(structure.status == 'ACTIVE' ? 'Deactivate' : 'Activate'),
              onPressed: () => _toggleStatus(context, ref, structure.status),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Assign to Student'),
              onPressed: () => context.push('/fees/assign?feeStructureId=$structureId'),
            ),
          ],
        ),
      ),
    );
  }
}
