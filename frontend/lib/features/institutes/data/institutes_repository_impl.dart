import 'package:dio/dio.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/institute.dart';
import '../domain/institutes_repository.dart';

class InstitutesRepositoryImpl implements InstitutesRepository {
  InstitutesRepositoryImpl() : _dio = DioClient().dio;

  final Dio _dio;

  @override
  Future<List<Institute>> getInstitutes() async {
    final data = await _request(() => _dio.get('/admin/institutes'));
    return (data as List<dynamic>)
        .map((item) => Institute.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<InstituteCreationResult> createInstitute({
    required String name,
    required String email,
    required String adminName,
    String? phone,
    String? address,
  }) async {
    final data = await _request(
      () => _dio.post('/admin/institutes', data: {
        'name': name,
        'email': email,
        'adminName': adminName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
      }),
    ) as Map<String, dynamic>;
    final credentials = data['credentials'] as Map<String, dynamic>;
    return InstituteCreationResult(
      institute: Institute.fromJson(data['institute'] as Map<String, dynamic>),
      instituteCode: credentials['instituteCode'] as String,
      initialPassword: credentials['initialPassword'] as String,
    );
  }

  @override
  Future<Institute> updateStatus(String id, InstituteStatus status) async {
    final data = await _request(
      () => _dio.patch('/admin/institutes/$id/status', data: {
        'status': status == InstituteStatus.active ? 'ACTIVE' : 'SUSPENDED',
      }),
    );
    return Institute.fromJson(data as Map<String, dynamic>);
  }

  Future<dynamic> _request(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final body = response.data as Map<String, dynamic>;
      return body['data'];
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message'] as String?
          : null;
      throw AppException(
        _friendlyMessage(error.response?.statusCode, message),
        statusCode: error.response?.statusCode,
      );
    }
  }

  String _friendlyMessage(int? statusCode, String? message) {
    if (statusCode == 401) return 'Your session has expired. Please sign in again.';
    if (statusCode == 403) return 'You do not have permission to manage institutes.';
    if (statusCode == 409) return 'An institute with that email already exists.';
    if (statusCode != null && statusCode >= 500) return 'The server is unavailable. Please try again.';
    if (message == 'Validation failed') return 'Please check the form and try again.';
    return message ?? 'Unable to complete the request. Check your connection and try again.';
  }
}
