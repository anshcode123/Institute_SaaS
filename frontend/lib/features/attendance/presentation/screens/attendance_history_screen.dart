import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/attendance_models.dart';
import '../providers/attendance_providers.dart';

const _statusFilters = ['PRESENT', 'ABSENT', 'LATE', 'EXCUSED'];

/// Filters: batch (pre-set when arriving from a batch screen), date,
/// status. Paginated - loads one page at a time rather than everything.
class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen(
      {super.key, this.initialBatchId, this.initialStudentId});

  final String? initialBatchId;
  final String? initialStudentId;

  @override
  ConsumerState<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends ConsumerState<AttendanceHistoryScreen> {
  String? _statusFilter;
  DateTime? _dateFilter;
  int _page = 1;
  bool _loading = true;
  String? _error;
  List<AttendanceRecord> _items = [];
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(attendanceRepositoryProvider).history(
            batchId: widget.initialBatchId,
            studentId: widget.initialStudentId,
            status: _statusFilter,
            date: _dateFilter,
            page: _page,
          );
      setState(() {
        _items = result.items;
        _total = result.total;
        _error = null;
      });
    } catch (e) {
      setState(() =>
          _error = e is AppException ? e.message : 'Failed to load history');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    setState(() {
      _dateFilter = picked;
      _page = 1;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_dateFilter != null
                      ? DateFormat.yMMMd().format(_dateFilter!)
                      : 'Any date'),
                  onPressed: _pickDate,
                ),
                if (_dateFilter != null)
                  ActionChip(
                    label: const Text('Clear date'),
                    onPressed: () {
                      setState(() {
                        _dateFilter = null;
                        _page = 1;
                      });
                      _load();
                    },
                  ),
                DropdownButton<String?>(
                  value: _statusFilter,
                  hint: const Text('Status'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All statuses')),
                    ..._statusFilters
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value;
                      _page = 1;
                    });
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
          if (_total > 20)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _page > 1
                        ? () {
                            setState(() => _page--);
                            _load();
                          }
                        : null,
                  ),
                  Text('Page $_page'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _items.length == 20
                        ? () {
                            setState(() => _page++);
                            _load();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return const EmptyState(
          message: 'No attendance records found.', icon: Icons.event_busy);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final record = _items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(record.student?.fullName ?? 'Unknown student'),
              subtitle: Text(
                '${record.batch?.name ?? '-'} • ${DateFormat.yMMMd().format(record.date)}\n'
                'Marked by ${record.markedBy?.name ?? '-'} at ${DateFormat.jm().format(record.markedAt)}',
              ),
              isThreeLine: true,
              trailing: _StatusChip(status: record.status),
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  Color _color() {
    switch (status) {
      case 'PRESENT':
        return Colors.green;
      case 'ABSENT':
        return Colors.red;
      case 'LATE':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
