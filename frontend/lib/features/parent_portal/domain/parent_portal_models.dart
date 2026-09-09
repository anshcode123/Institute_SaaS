import '../../attendance/domain/attendance_models.dart';
import '../../fees/domain/fee_models.dart';
import '../../tests/domain/test_models.dart';

class LinkedChild {
  final String id;
  final String firstName;
  final String lastName;
  final String studentCode;
  final String status;
  final String? batchName;
  final String relationship;

  const LinkedChild({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.studentCode,
    required this.status,
    required this.relationship,
    this.batchName,
  });

  String get fullName => '$firstName $lastName';

  factory LinkedChild.fromJson(Map<String, dynamic> json) => LinkedChild(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        studentCode: json['studentCode'] as String,
        status: json['status'] as String,
        relationship: json['relationship'] as String,
        batchName:
            json['batch'] != null ? (json['batch']['name'] as String?) : null,
      );
}

/// Same shape as StudentDashboard but without the unread-notification
/// count (notifications are the parent's own, not per-child) - kept as
/// its own small class rather than reusing StudentDashboard so the two
/// portals' payloads can evolve independently.
class ChildDashboard {
  final LinkedChild? student;
  final StudentAttendanceSummary? attendanceSummary;
  final StudentFeesSummary feesSummary;
  final StudentTestResult? latestResult;

  const ChildDashboard(
      {required this.feesSummary,
      this.student,
      this.attendanceSummary,
      this.latestResult});

  factory ChildDashboard.fromJson(Map<String, dynamic> json) => ChildDashboard(
        attendanceSummary: json['attendanceSummary'] != null
            ? StudentAttendanceSummary.fromJson(
                json['attendanceSummary'] as Map<String, dynamic>)
            : null,
        feesSummary: StudentFeesSummary.fromJson(
            json['feesSummary'] as Map<String, dynamic>),
        latestResult: json['latestResult'] != null
            ? StudentTestResult.fromJson(
                json['latestResult'] as Map<String, dynamic>)
            : null,
      );
}
