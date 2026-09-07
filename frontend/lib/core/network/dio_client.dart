import 'package:dio/dio.dart';
import '../../features/auth/data/auth_interceptor.dart';
import '../../features/auth/data/auth_storage_keys.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';

/// Central wrapper around Dio so interceptors (auth token, token refresh,
/// error mapping) are always attached to all HTTP requests across the application.
class DioClient {
  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      AuthInterceptor(
        dio: _dio,
        onSessionExpired: () =>
            onSessionExpired?.call() ?? _defaultSessionExpired(),
      ),
    );
  }

  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio _dio;
  Future<void> Function()? onSessionExpired;

  Dio get dio => _dio;

  static Future<void> _defaultSessionExpired() async {
    await SecureStorage.instance.delete(AuthStorageKeys.accessToken);
    await SecureStorage.instance.delete(AuthStorageKeys.refreshToken);
    await SecureStorage.instance.delete(AuthStorageKeys.userJson);
  }
}
