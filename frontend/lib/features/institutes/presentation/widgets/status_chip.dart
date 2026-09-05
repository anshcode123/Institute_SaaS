import 'package:flutter/material.dart';
import '../../domain/institute.dart';

class InstituteStatusChip extends StatelessWidget {
  const InstituteStatusChip({super.key, required this.status});

  final InstituteStatus status;

  @override
  Widget build(BuildContext context) {
    final active = status == InstituteStatus.active;
    final color = active ? Colors.green : Colors.orange;
    return Chip(
      avatar: Icon(active ? Icons.check_circle : Icons.pause_circle, size: 16, color: color),
      label: Text(active ? 'Active' : 'Suspended'),
      visualDensity: VisualDensity.compact,
    );
  }
}
