import 'package:dio/dio.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/batch_models.dart';
import '../domain/batch_repository.dart';

class BatchRepositoryImpl implements BatchRepository {
  final Dio _dio = DioClient().dio;

  @override
  Future<PaginatedResult<Batch>> list({String? query, String? status, int page = 1}) async {
    final data = await _get('/batches', queryParameters: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (status != null) 'status': status,
      'page': page,
    });
    return PaginatedResult.fromJson(data, Batch.fromJson);
  }

  @override
  Future<Batch> getById(String id) async => Batch.fromJson(await _get('/batches/$id'));

  @override
  Future<Batch> create(Map<String, dynamic> data) async =>
      Batch.fromJson(await _send('POST', '/batches', data));

  @override
  Future<Batch> update(String id, Map<String, dynamic> data) async =>
      Batch.fromJson(await _send('PATCH', '/batches/$id', data));

  @override
  Future<void> deactivate(String id) => _send('DELETE', '/batches/$id', null);

  @override
  Future<Batch> addStudents(String batchId, List<String> studentIds) async =>
      Batch.fromJson(await _send('POST', '/batches/$batchId/students', {'studentIds': studentIds}));

  @override
  Future<Batch> removeStudents(String batchId, List<String> studentIds) async =>
      Batch.fromJson(await _send('DELETE', '/batches/$batchId/students', {'studentIds': studentIds}));

  @override
  Future<Batch> assignTeachers(String batchId, List<String> teacherIds) async =>
      Batch.fromJson(await _send('POST', '/batches/$batchId/teachers', {'teacherIds': teacherIds}));

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
