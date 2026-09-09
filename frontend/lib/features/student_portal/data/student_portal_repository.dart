import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/paginated_result.dart';
import '../../attendance/domain/attendance_models.dart';
import '../../fees/domain/fee_models.dart';
import '../../students/domain/student_models.dart';
import '../../tests/domain/test_models.dart';
import '../domain/student_dashboard.dart';

/// Every call here hits a /student/* endpoint - the backend derives
/// "which student" from the authenticated token, never from anything
/// this repository sends. No studentId parameter exists on any method
/// here on purpose.
class StudentPortalRepository {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>> _get(String path,
      {Map<String, dynamic>? query}) async {
    final response = await _dio.get(path, queryParameters: query);
    return (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }

  Future<Student> getMyProfile() async =>
      Student.fromJson(await _get('/student/me'));

  Future<StudentDashboard> getMyDashboard() async =>
      StudentDashboard.fromJson(await _get('/student/dashboard'));

  Future<PaginatedResult<AttendanceRecord>> getMyAttendance() async {
    return PaginatedResult.fromJson(
        await _get('/student/attendance'), AttendanceRecord.fromJson);
  }

  Future<({String attendanceQr, String? leavingQr})> getMyQrCodes() async {
    final data = await _get('/student/attendance-qr');
    return (
      attendanceQr: data['attendanceQr'] as String,
      leavingQr: data['leavingQr'] as String?
    );
  }

  Future<StudentFeesResult> getMyFees() async =>
      StudentFeesResult.fromJson(await _get('/student/fees'));

  Future<PaginatedResult<Payment>> getMyPayments() async =>
      PaginatedResult.fromJson(
          await _get('/student/payments'), Payment.fromJson);

  Future<Receipt> getMyReceipt(String receiptId) async =>
      Receipt.fromJson(await _get('/student/receipts/$receiptId'));

  Future<List<StudentTestResult>> getMyResults() async {
    final response = await _dio.get('/student/results');
    final list = (response.data as Map<String, dynamic>)['data'] as List;
    return list
        .map((e) => StudentTestResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StudentResultDetail> getMyResultDetail(String resultId) async =>
      StudentResultDetail.fromJson(await _get('/student/results/$resultId'));
}
