import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';
import 'auth_interceptor.dart';
import 'auth_storage_keys.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({Future<void> Function()? onSessionExpired})
      : _dio = DioClient().dio {
    // Guarded so re-creating the repository (e.g. hot reload) doesn't
    // stack duplicate interceptors on the shared Dio singleton.
    final alreadyAttached = _dio.interceptors.any((i) => i is AuthInterceptor);
    if (!alreadyAttached) {
      _dio.interceptors.add(
        AuthInterceptor(
          dio: _dio,
          onSessionExpired: onSessionExpired ?? () async => logout(),
        ),
      );
    }
  }

  final Dio _dio;

  @override
  Future<AuthSession> loginSuperAdmin({
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/super-admin/login', {
      'email': email,
      'password': password,
    });
    return _persistSession(response);
  }

  @override
  Future<AuthSession> loginInstitute({
    required String instituteCode,
    required String password,
  }) async {
    final response = await _post('/auth/institute/login', {
      'instituteCode': instituteCode,
      'password': password,
    });
    return _persistSession(response);
  }

  @override
  Future<AuthSession> loginTeacher({
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/teacher/login', {
      'email': email,
      'password': password,
    });
    return _persistSession(response);
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final accessToken = await SecureStorage.instance.read(
      AuthStorageKeys.accessToken,
    );
    final refreshToken = await SecureStorage.instance.read(
      AuthStorageKeys.refreshToken,
    );
    final userJson = await SecureStorage.instance.read(
      AuthStorageKeys.userJson,
    );

    if (accessToken == null || refreshToken == null || userJson == null) {
      return null;
    }

    final user = AuthUser.fromJson(
      jsonDecode(userJson) as Map<String, dynamic>,
    );
    if (!_isExpired(accessToken)) {
      return AuthSession(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }

    try {
      final refreshed = await _refreshTokens(refreshToken, user);
      await SecureStorage.instance.write(
        AuthStorageKeys.accessToken,
        refreshed.accessToken,
      );
      await SecureStorage.instance.write(
        AuthStorageKeys.refreshToken,
        refreshed.refreshToken,
      );
      return AuthSession(
        user: user,
        accessToken: refreshed.accessToken,
        refreshToken: refreshed.refreshToken,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        await logout();
        return null;
      }
      return AuthSession(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await SecureStorage.instance.read(
      AuthStorageKeys.refreshToken,
    );
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
    String path,
    Map<String, dynamic> body,
  ) async {
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

    await SecureStorage.instance.write(
      AuthStorageKeys.accessToken,
      accessToken,
    );
    await SecureStorage.instance.write(
      AuthStorageKeys.refreshToken,
      refreshToken,
    );
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
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  bool _isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final exp = (payload['exp'] as num?)?.toInt();
      return exp == null || DateTime.now().millisecondsSinceEpoch >= exp * 1000;
    } on FormatException {
      return true;
    }
  }

  Future<AuthSession> _refreshTokens(String refreshToken, AuthUser user) async {
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    final response = await refreshDio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return AuthSession(
      user: user,
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }
}
