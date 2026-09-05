import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/attendance_models.dart';
import '../domain/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final Dio _dio = DioClient().dio;

  String _dateOnly(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  @override
  Future<ScanResult> scan({required String qrToken, required String batchId}) async {
    final data = await _send('POST', '/attendance/scan', {'qrToken': qrToken, 'batchId': batchId});
    return ScanResult.fromJson(data);
  }

  @override
  Future<List<AttendanceRecord>> markManual({
    required String batchId,
    DateTime? date,
    required List<Map<String, String>> entries,
  }) async {
    try {
      final response = await _dio.post('/attendance/manual', data: {
        'batchId': batchId,
        if (date != null) 'date': _dateOnly(date),
        'entries': entries,
      });
      final list = (response.data as Map<String, dynamic>)['data'] as List;
      return list.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  @override
  Future<PaginatedResult<AttendanceRecord>> history({
    String? batchId,
    String? studentId,
    String? status,
    DateTime? date,
    int page = 1,
  }) async {
    final data = await _get('/attendance', queryParameters: {
      if (batchId != null) 'batchId': batchId,
      if (studentId != null) 'studentId': studentId,
      if (status != null) 'status': status,
      if (date != null) 'date': _dateOnly(date),
      'page': page,
    });
    return PaginatedResult.fromJson(data, AttendanceRecord.fromJson);
  }

  @override
  Future<StudentAttendanceSummary> studentSummary(String studentId) async {
    final data = await _get('/attendance/students/$studentId/summary');
    return StudentAttendanceSummary.fromJson(data);
  }

  @override
  Future<BatchAttendanceSummary> batchSummary(String batchId, {DateTime? date}) async {
    final data = await _get('/attendance/batches/$batchId/summary', queryParameters: {
      if (date != null) 'date': _dateOnly(date),
    });
    return BatchAttendanceSummary.fromJson(data);
  }

  Future<Map<String, dynamic>> _get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  Future<Map<String, dynamic>> _send(String method, String path, Map<String, dynamic>? body) async {
    try {
      final response = await _dio.request(path, data: body, options: Options(method: method));
      return (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  AppException _toAppException(DioException e) {
    final message = e.response?.data is Map
        ? (e.response?.data['message'] as String? ?? 'Request failed')
        : 'Request failed';
    return AppException(message, statusCode: e.response?.statusCode);
  }
}
