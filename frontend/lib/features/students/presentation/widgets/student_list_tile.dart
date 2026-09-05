import 'package:flutter/material.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/student_models.dart';

class StudentListTile extends StatelessWidget {
  const StudentListTile({super.key, required this.student, required this.onTap});

  final Student student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundImage:
              student.profilePhoto != null ? NetworkImage(student.profilePhoto!) : null,
          child: student.profilePhoto == null ? Text(student.firstName[0]) : null,
        ),
        title: Text(student.fullName),
        subtitle: Text(
          '${student.studentCode}${student.batch != null ? ' • ${student.batch!.name}' : ''}',
        ),
        trailing: StatusBadge(status: student.status),
      ),
    );
  }
}
