import 'package:dio/dio.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/parent_models.dart';
import '../domain/parent_repository.dart';

class ParentRepositoryImpl implements ParentRepository {
  final Dio _dio = DioClient().dio;

  @override
  Future<PaginatedResult<Parent>> list({String? query, String? status, int page = 1}) async {
    final data = await _get('/parents', queryParameters: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (status != null) 'status': status,
      'page': page,
    });
    return PaginatedResult.fromJson(data, Parent.fromJson);
  }

  @override
  Future<Parent> getById(String id) async => Parent.fromJson(await _get('/parents/$id'));

  @override
  Future<Parent> create(Map<String, dynamic> data) async =>
      Parent.fromJson(await _send('POST', '/parents', data));

  @override
  Future<Parent> update(String id, Map<String, dynamic> data) async =>
      Parent.fromJson(await _send('PATCH', '/parents/$id', data));

  @override
  Future<void> deactivate(String id) => _send('DELETE', '/parents/$id', null);

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
