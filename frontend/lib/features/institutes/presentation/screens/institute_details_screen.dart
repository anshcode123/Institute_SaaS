import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/institute.dart';
import '../providers/institutes_provider.dart';
import '../widgets/status_chip.dart';

class InstituteDetailsScreen extends ConsumerWidget {
  const InstituteDetailsScreen({super.key, required this.institute});
  final Institute institute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(institutesProvider).institutes.where((item) => item.id == institute.id);
    final current = matches.isEmpty ? institute : matches.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Institute details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(current.name, style: Theme.of(context).textTheme.headlineSmall)),
                    InstituteStatusChip(status: current.status),
                  ]),
                  const Divider(height: 32),
                  _detail('Institute ID', current.instituteCode),
                  _detail('Email', current.email),
                  _detail('Phone', current.phone),
                  _detail('Address', current.address),
                  _detail('Created', current.createdAt?.toLocal().toString()),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      try {
                        await ref.read(institutesProvider.notifier).updateStatus(current);
                        if (context.mounted) Navigator.pop(context);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to update status.')));
                        }
                      }
                    },
                    icon: Icon(current.status == InstituteStatus.active ? Icons.pause : Icons.play_arrow),
                    label: Text(current.status == InstituteStatus.active ? 'Suspend institute' : 'Activate institute'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String? value) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value?.isNotEmpty == true ? value! : 'Not provided')),
        ]),
      );
}
