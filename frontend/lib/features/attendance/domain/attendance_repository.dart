import '../../../core/network/paginated_result.dart';
import 'attendance_models.dart';

abstract class AttendanceRepository {
  Future<ScanResult> scan({required String qrToken, required String batchId});

  Future<List<AttendanceRecord>> markManual({
    required String batchId,
    DateTime? date,
    required List<Map<String, String>> entries,
  });

  Future<PaginatedResult<AttendanceRecord>> history({
    String? batchId,
    String? studentId,
    String? status,
    DateTime? date,
    int page = 1,
  });

  Future<StudentAttendanceSummary> studentSummary(String studentId);

  Future<BatchAttendanceSummary> batchSummary(String batchId, {DateTime? date});
}
