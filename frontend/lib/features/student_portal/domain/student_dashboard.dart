import '../../attendance/domain/attendance_models.dart';
import '../../fees/domain/fee_models.dart';
import '../../students/domain/student_models.dart';
import '../../tests/domain/test_models.dart';

/// Combines existing domain models (Student, attendance/fee summaries,
/// latest test result) into one dashboard payload - reuses the same
/// model classes the Institute Admin app already uses, no duplicate
/// parsing logic for any of these.
class StudentDashboard {
  final Student student;
  final StudentAttendanceSummary? attendanceSummary;
  final StudentFeesSummary feesSummary;
  final StudentTestResult? latestResult;
  final int unreadNotificationCount;

  const StudentDashboard({
    required this.student,
    required this.feesSummary,
    required this.unreadNotificationCount,
    this.attendanceSummary,
    this.latestResult,
  });

  factory StudentDashboard.fromJson(Map<String, dynamic> json) =>
      StudentDashboard(
        student: Student.fromJson(json['student'] as Map<String, dynamic>),
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
        unreadNotificationCount: json['unreadNotificationCount'] as int,
      );
}
