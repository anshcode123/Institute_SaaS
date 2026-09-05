import 'package:dio/dio.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/student_models.dart';
import '../domain/student_repository.dart';

class StudentRepositoryImpl implements StudentRepository {
  final Dio _dio = DioClient().dio;

  @override
  Future<PaginatedResult<Student>> list({
    String? query,
    String? status,
    String? batchId,
    int page = 1,
  }) async {
    final data = await _get('/students', queryParameters: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (status != null) 'status': status,
      if (batchId != null) 'batchId': batchId,
      'page': page,
    });
    return PaginatedResult.fromJson(data, Student.fromJson);
  }

  @override
  Future<Student> getById(String id) async {
    final data = await _get('/students/$id');
    return Student.fromJson(data);
  }

  @override
  Future<Student> create(Map<String, dynamic> data) async {
    final result = await _send('POST', '/students', data);
    return Student.fromJson(result);
  }

  @override
  Future<Student> update(String id, Map<String, dynamic> data) async {
    final result = await _send('PATCH', '/students/$id', data);
    return Student.fromJson(result);
  }

  @override
  Future<void> deactivate(String id) => _send('DELETE', '/students/$id', null);

  @override
  Future<void> linkParent(String studentId, String parentId, {String? relationship}) {
    return _send('POST', '/students/$studentId/parent', {
      'parentId': parentId,
      if (relationship != null) 'relationship': relationship,
    });
  }

  @override
  Future<void> unlinkParent(String studentId, String parentId) {
    return _send('DELETE', '/students/$studentId/parent/$parentId', null);
  }

  @override
  Future<Student> assignBatch(String studentId, String batchId) async {
    final result = await _send('POST', '/students/$studentId/batch', {'batchId': batchId});
    return Student.fromJson(result);
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
      final response = await _dio.request(
        path,
        data: body,
        options: Options(method: method),
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
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
