import 'package:flutter/material.dart';
import '../../domain/institute.dart';
import 'status_chip.dart';

class InstituteCard extends StatelessWidget {
  const InstituteCard({
    super.key,
    required this.institute,
    required this.onTap,
    required this.onStatusChange,
  });

  final Institute institute;
  final VoidCallback onTap;
  final VoidCallback onStatusChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(child: Text(institute.name.substring(0, 1).toUpperCase())),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(institute.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('${institute.instituteCode}  •  ${institute.email}'),
                    if (institute.phone != null) Text(institute.phone!),
                  ],
                ),
              ),
              InstituteStatusChip(status: institute.status),
              PopupMenuButton<String>(
                onSelected: (_) => onStatusChange(),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'status',
                    child: Text(institute.status == InstituteStatus.active ? 'Suspend' : 'Activate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
