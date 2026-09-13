import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';
import 'auth_storage_keys.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({Future<void> Function()? onSessionExpired})
      : _dio = DioClient().dio {
    if (onSessionExpired != null) {
      DioClient().onSessionExpired = onSessionExpired;
    }
  }

  final Dio _dio;

  @override
  Future<AuthSession> loginSuperAdmin(
      {required String email, required String password}) async {
    final response = await _post(
        '/auth/super-admin/login', {'email': email, 'password': password});
    return _persistSession(response);
  }

  @override
  Future<AuthSession> loginInstitute({
    required String instituteCode,
    required String password,
  }) async {
    final response = await _post(
      '/auth/institute/login',
      {'instituteCode': instituteCode, 'password': password},
    );
    return _persistSession(response);
  }

  @override
  Future<AuthSession> loginTeacher(
      {required String email, required String password}) async {
    final response = await _post(
        '/auth/teacher/login', {'email': email, 'password': password});
    return _persistSession(response);
  }

  @override
  Future<AuthSession> loginStudent(
      {required String email, required String password}) async {
    final response = await _post(
        '/auth/student/login', {'email': email, 'password': password});
    return _persistSession(response);
  }

  @override
  Future<AuthSession> loginParent(
      {required String email, required String password}) async {
    final response = await _post(
        '/auth/parent/login', {'email': email, 'password': password});
    return _persistSession(response);
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final accessToken =
        await SecureStorage.instance.read(AuthStorageKeys.accessToken);
    final refreshToken =
        await SecureStorage.instance.read(AuthStorageKeys.refreshToken);
    final userJson =
        await SecureStorage.instance.read(AuthStorageKeys.userJson);

    if (accessToken == null || refreshToken == null || userJson == null) {
      return null;
    }

    return AuthSession(
      user: AuthUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> logout() async {
    final refreshToken =
        await SecureStorage.instance.read(AuthStorageKeys.refreshToken);
    if (refreshToken != null) {
      // Best-effort - even if this call fails, clear local storage below
      // so the user is logged out on-device regardless.
      try {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {}
    }
    await SecureStorage.instance.delete(AuthStorageKeys.accessToken);
    await SecureStorage.instance.delete(AuthStorageKeys.refreshToken);
    await SecureStorage.instance.delete(AuthStorageKeys.userJson);
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(path, data: body);
      return (response.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message'] as String? ?? 'Login failed')
          : 'Login failed';
      throw AppException(message, statusCode: e.response?.statusCode);
    }
  }

  Future<AuthSession> _persistSession(Map<String, dynamic> data) async {
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;

    await SecureStorage.instance
        .write(AuthStorageKeys.accessToken, accessToken);
    await SecureStorage.instance
        .write(AuthStorageKeys.refreshToken, refreshToken);
    await SecureStorage.instance.write(
      AuthStorageKeys.userJson,
      jsonEncode({
        'id': user.id,
        'name': user.name,
        'role': user.role,
        'email': user.email,
        'instituteId': user.instituteId,
      }),
    );

    return AuthSession(
        user: user, accessToken: accessToken, refreshToken: refreshToken);
  }
}
