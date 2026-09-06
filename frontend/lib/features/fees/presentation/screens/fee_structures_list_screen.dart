import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/currency_text.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../providers/fee_providers.dart';
import '../widgets/fee_status_chip.dart';

class FeeStructuresListScreen extends ConsumerWidget {
  const FeeStructuresListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStructures = ref.watch(feeStructuresProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Fee Structures')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/fees/structures/new'),
        child: const Icon(Icons.add),
      ),
      body: asyncStructures.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load fee structures',
          onRetry: () => ref.invalidate(feeStructuresProvider(null)),
        ),
        data: (structures) => structures.isEmpty
            ? const EmptyState(
                message: 'No fee structures yet. Tap + to create one.',
                icon: Icons.receipt_long_outlined,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(feeStructuresProvider(null)),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 8),
                  itemCount: structures.length,
                  itemBuilder: (context, index) {
                    final structure = structures[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        onTap: () => context.push('/fees/structures/${structure.id}'),
                        title: Text(structure.name),
                        subtitle: Text(
                          '${formatCurrency(structure.totalAmount, currency: structure.currency)} • '
                          '${structure.installments.length} installments'
                          '${structure.batchName != null ? ' • ${structure.batchName}' : ''}',
                        ),
                        trailing: FeeStatusChip(status: structure.status),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
