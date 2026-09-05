import 'package:dio/dio.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/teacher_models.dart';
import '../domain/teacher_repository.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  final Dio _dio = DioClient().dio;

  @override
  Future<PaginatedResult<Teacher>> list({String? query, String? status, int page = 1}) async {
    final data = await _get('/teachers', queryParameters: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (status != null) 'status': status,
      'page': page,
    });
    return PaginatedResult.fromJson(data, Teacher.fromJson);
  }

  @override
  Future<Teacher> getById(String id) async => Teacher.fromJson(await _get('/teachers/$id'));

  @override
  Future<Teacher> create(Map<String, dynamic> data) async =>
      Teacher.fromJson(await _send('POST', '/teachers', data));

  @override
  Future<Teacher> update(String id, Map<String, dynamic> data) async =>
      Teacher.fromJson(await _send('PATCH', '/teachers/$id', data));

  @override
  Future<void> deactivate(String id) => _send('DELETE', '/teachers/$id', null);

  @override
  Future<Teacher> assignBatches(String teacherId, List<String> batchIds) async =>
      Teacher.fromJson(await _send('POST', '/teachers/$teacherId/batches', {'batchIds': batchIds}));

  @override
  Future<Map<String, dynamic>> createLogin(String teacherId) async {
    return _send('POST', '/teachers/$teacherId/login', null);
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
