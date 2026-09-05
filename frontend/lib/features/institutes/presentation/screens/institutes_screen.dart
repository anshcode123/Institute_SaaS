import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/institute.dart';
import '../providers/institutes_provider.dart';
import '../widgets/institute_card.dart';

class InstitutesScreen extends ConsumerWidget {
  const InstitutesScreen({super.key});

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, Institute institute) async {
    final next = institute.status == InstituteStatus.active ? 'suspend' : 'activate';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${next[0].toUpperCase()}${next.substring(1)} institute?'),
        content: Text('Are you sure you want to $next ${institute.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(next)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(institutesProvider.notifier).updateStatus(institute);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Institute ${next}d.')));
      }
    } catch (_) {
      if (context.mounted) {
        final message = ref.read(institutesProvider).errorMessage ?? 'Unable to update institute status.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(institutesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Institutes'),
        actions: [
          IconButton(onPressed: state.isLoading ? null : () => ref.read(institutesProvider.notifier).load(), icon: const Icon(Icons.refresh)),
          FilledButton.icon(onPressed: () => context.push('/institutes/create'), icon: const Icon(Icons.add), label: const Text('Create')),
        ],
      ),
      body: state.isLoading && state.institutes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.institutes.isEmpty
              ? _ErrorState(message: state.errorMessage!, onRetry: () => ref.read(institutesProvider.notifier).load())
              : state.institutes.isEmpty
                  ? _EmptyState(onCreate: () => context.push('/institutes/create'))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(institutesProvider.notifier).load(),
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Text('${state.institutes.length} institute${state.institutes.length == 1 ? '' : 's'}', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          ...state.institutes.map(
                            (institute) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InstituteCard(
                                institute: institute,
                                onTap: () => context.push('/institutes/${institute.id}', extra: institute),
                                onStatusChange: () => _changeStatus(context, ref, institute),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.business_outlined, size: 56),
          const SizedBox(height: 16),
          const Text('No institutes yet'),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Create institute')),
        ]),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ]),
      );
}
