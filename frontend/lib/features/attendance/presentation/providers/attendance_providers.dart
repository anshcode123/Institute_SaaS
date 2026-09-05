import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/attendance_repository_impl.dart';
import '../../domain/attendance_models.dart';
import '../../domain/attendance_repository.dart';

final attendanceRepositoryProvider =
    Provider<AttendanceRepository>((ref) => AttendanceRepositoryImpl());

/// Live counts for the batch attendance screen - refetched after every
/// scan/manual mark so "Present: 24 / Remaining: 6" stays accurate.
final batchAttendanceSummaryProvider =
    FutureProvider.family<BatchAttendanceSummary, String>((ref, batchId) async {
  return ref.watch(attendanceRepositoryProvider).batchSummary(batchId);
});

final studentAttendanceSummaryProvider =
    FutureProvider.family<StudentAttendanceSummary, String>((ref, studentId) async {
  return ref.watch(attendanceRepositoryProvider).studentSummary(studentId);
});
