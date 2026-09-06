import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../parents/domain/parent_models.dart';
import '../../../parents/presentation/providers/parent_providers.dart';
import '../providers/student_providers.dart';

/// Search existing parents and link one to this student with a
/// relationship type. Deliberately reuses the Parent repository rather
/// than duplicating parent search logic.
class LinkParentScreen extends ConsumerStatefulWidget {
  const LinkParentScreen({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<LinkParentScreen> createState() => _LinkParentScreenState();
}

class _LinkParentScreenState extends ConsumerState<LinkParentScreen> {
  List<Parent> _results = [];
  bool _loading = false;
  String? _error;
  String _relationship = 'GUARDIAN';

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final result =
          await ref.read(parentRepositoryProvider).list(query: query);
      setState(() {
        _results = result.items;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e is AppException ? e.message : 'Search failed');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _link(Parent parent) async {
    try {
      await ref
          .read(studentRepositoryProvider)
          .linkParent(widget.studentId, parent.id, relationship: _relationship);
      ref.invalidate(studentDetailProvider(widget.studentId));
      if (mounted) context.pop();
    } catch (e) {
      setState(() =>
          _error = e is AppException ? e.message : 'Failed to link parent');
    }
  }

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link Parent')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search parent by name or phone',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: _search,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _relationship,
                  decoration: const InputDecoration(
                      labelText: 'Relationship', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'FATHER', child: Text('Father')),
                    DropdownMenuItem(value: 'MOTHER', child: Text('Mother')),
                    DropdownMenuItem(
                        value: 'GUARDIAN', child: Text('Guardian')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (v) =>
                      setState(() => _relationship = v ?? 'GUARDIAN'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final parent = _results[index];
                return ListTile(
                  title: Text(parent.name),
                  subtitle: Text(parent.phone ?? parent.email ?? ''),
                  trailing: FilledButton(
                    onPressed: () => _link(parent),
                    child: const Text('Link'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
