import 'package:flutter/material.dart';

class FeeStatusChip extends StatelessWidget {
  const FeeStatusChip({super.key, required this.status});

  final String status;

  Color _color() {
    switch (status) {
      case 'PAID':
      case 'ACTIVE':
        return Colors.green;
      case 'PARTIALLY_PAID':
        return Colors.blue;
      case 'OVERDUE':
        return Colors.red;
      case 'CANCELLED':
      case 'INACTIVE':
        return Colors.grey;
      default:
        return Colors.orange;
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
      child: Text(
        status.replaceAll('_', ' '),
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
