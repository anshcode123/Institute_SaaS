import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/paginated_result.dart';
import '../../attendance/domain/attendance_models.dart';
import '../../fees/domain/fee_models.dart';
import '../../tests/domain/test_models.dart';
import '../domain/parent_portal_models.dart';

/// Every call takes an explicit studentId - but that's only ever used to
/// build the URL path; the backend independently re-verifies the
/// StudentParent link on every single call (see parent-access.js). This
/// repository being handed a wrong id changes nothing: the server
/// rejects it regardless of what the Flutter UI believes is selected.
class ParentPortalRepository {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await _dio.get(path);
    return (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }

  Future<List<LinkedChild>> getMyChildren() async {
    final response = await _dio.get('/parent/children');
    final list = (response.data as Map<String, dynamic>)['data'] as List;
    return list
        .map((e) => LinkedChild.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChildDashboard> getChildDashboard(String studentId) async =>
      ChildDashboard.fromJson(
          await _get('/parent/children/$studentId/dashboard'));

  Future<PaginatedResult<AttendanceRecord>> getChildAttendance(
          String studentId) async =>
      PaginatedResult.fromJson(
          await _get('/parent/children/$studentId/attendance'),
          AttendanceRecord.fromJson);

  Future<StudentFeesResult> getChildFees(String studentId) async =>
      StudentFeesResult.fromJson(
          await _get('/parent/children/$studentId/fees'));

  Future<List<StudentTestResult>> getChildResults(String studentId) async {
    final response = await _dio.get('/parent/children/$studentId/results');
    final list = (response.data as Map<String, dynamic>)['data'] as List;
    return list
        .map((e) => StudentTestResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StudentResultDetail> getChildResultDetail(
          String studentId, String resultId) async =>
      StudentResultDetail.fromJson(
          await _get('/parent/children/$studentId/results/$resultId'));
}
