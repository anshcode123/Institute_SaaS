import 'package:flutter/material.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/student_models.dart';

class StudentGridCard extends StatelessWidget {
  const StudentGridCard({super.key, required this.student, required this.onTap});

  final Student student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: student.profilePhoto != null
                        ? NetworkImage(student.profilePhoto!)
                        : null,
                    child: student.profilePhoto == null
                        ? Text(student.firstName[0])
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          student.studentCode,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (student.batch != null)
                Text(
                  student.batch!.name,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              StatusBadge(status: student.status),
            ],
          ),
        ),
      ),
    );
  }
}
