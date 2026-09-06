import 'package:flutter/material.dart';

class TestStatusChip extends StatelessWidget {
  const TestStatusChip({super.key, required this.status});

  final String status;

  Color _color() {
    switch (status) {
      case 'PUBLISHED':
        return Colors.green;
      case 'COMPLETED':
        return Colors.blue;
      case 'SCHEDULED':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.grey;
      default: // DRAFT
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
