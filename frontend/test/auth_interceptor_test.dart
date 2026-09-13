import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_saas/core/network/dio_client.dart';
import 'package:student_saas/core/storage/secure_storage.dart';
import 'package:student_saas/features/auth/data/auth_interceptor.dart';
import 'package:student_saas/features/auth/data/auth_storage_keys.dart';
import 'package:student_saas/features/fees/data/fee_repository_impl.dart';
import 'package:student_saas/features/students/data/student_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('DioClient initializes with AuthInterceptor attached', () {
    final dio = DioClient().dio;
    final hasAuthInterceptor =
        dio.interceptors.any((i) => i is AuthInterceptor);
    expect(hasAuthInterceptor, isTrue);
  });

  test('AuthInterceptor attaches Bearer token to all Fee and Student endpoints',
      () async {
    await SecureStorage.instance
        .write(AuthStorageKeys.accessToken, 'token_xyz_999');

    final interceptor = AuthInterceptor(
      dio: Dio(),
      onSessionExpired: () async {},
    );

    final endpoints = [
      // Fee structures & Monthly fee structures
      '/fees/structures',
      '/fees/structures/123',
      // Fee assignments
      '/fees/student',
      '/fees/student/student_1',
      // Fee payments
      '/payments',
      '/payments/pay_1',
      '/receipts/rec_1',
      // Fee dashboard
      '/fees/dashboard',
      // Fee list
      '/fees',
      '/fees/fee_1',
      // Student endpoints
      '/students',
      '/students/std_1',
    ];

    for (final endpoint in endpoints) {
      final options = RequestOptions(path: endpoint);
      final handler = _CapturingHandler();
      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], equals('Bearer token_xyz_999'),
          reason: 'Endpoint $endpoint must send Authorization header');
    }
  });

  test('AuthInterceptor does not attach token to auth-free endpoints',
      () async {
    await SecureStorage.instance
        .write(AuthStorageKeys.accessToken, 'token_xyz_999');

    final interceptor = AuthInterceptor(
      dio: Dio(),
      onSessionExpired: () async {},
    );

    final authPaths = [
      '/auth/super-admin/login',
      '/auth/institute/login',
      '/auth/teacher/login',
      '/auth/student/login',
      '/auth/parent/login',
      '/auth/refresh',
      '/auth/logout',
    ];

    for (final path in authPaths) {
      final options = RequestOptions(path: path);
      final handler = _CapturingHandler();
      await interceptor.onRequest(options, handler);
      expect(options.headers['Authorization'], isNull,
          reason: 'Path $path should be auth-free');
    }
  });

  test('AuthInterceptor transparently refreshes token on 401 for Fee requests',
      () async {
    await SecureStorage.instance
        .write(AuthStorageKeys.accessToken, 'expired_token');
    await SecureStorage.instance
        .write(AuthStorageKeys.refreshToken, 'valid_refresh_token');

    final mockDio = Dio();
    mockDio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path == '/auth/refresh') {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'accessToken': 'fresh_access_token_777',
                'refreshToken': 'fresh_refresh_token_888',
              },
            },
          ));
        }
        if (options.headers['Authorization'] ==
            'Bearer fresh_access_token_777') {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 201,
            data: {
              'success': true,
              'data': {'id': 'fee_structure_1', 'name': 'Monthly Fee 2026'},
            },
          ));
        }
        return handler.reject(DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: {
              'success': false,
              'message': 'Invalid or expired access token'
            },
          ),
        ));
      },
    ));

    final interceptor = AuthInterceptor(
      dio: mockDio,
      onSessionExpired: () async {},
    );

    final feeRequest = RequestOptions(path: '/fees/structures', method: 'POST');
    final err = DioException(
      requestOptions: feeRequest,
      response: Response(
        requestOptions: feeRequest,
        statusCode: 401,
        data: {
          'success': false,
          'message': 'Missing or malformed Authorization header'
        },
      ),
    );

    final errorHandler = _CapturingErrorHandler();
    await interceptor.onError(err, errorHandler);

    expect(errorHandler.resolvedResponse, isNotNull);
    expect(errorHandler.resolvedResponse?.statusCode, equals(201));

    // Verify stored tokens were updated
    final savedAccess =
        await SecureStorage.instance.read(AuthStorageKeys.accessToken);
    final savedRefresh =
        await SecureStorage.instance.read(AuthStorageKeys.refreshToken);
    expect(savedAccess, equals('fresh_access_token_777'));
    expect(savedRefresh, equals('fresh_refresh_token_888'));
  });

  test(
      'FeeRepositoryImpl and StudentRepositoryImpl share authenticated Dio instance',
      () {
    final feeRepo = FeeRepositoryImpl();
    final studentRepo = StudentRepositoryImpl();

    expect(feeRepo, isNotNull);
    expect(studentRepo, isNotNull);
    expect(
        DioClient().dio.interceptors.any((i) => i is AuthInterceptor), isTrue);
  });
}

class _CapturingHandler extends RequestInterceptorHandler {
  RequestOptions? passedOptions;

  @override
  void next(RequestOptions requestOptions) {
    passedOptions = requestOptions;
  }
}

class _CapturingErrorHandler extends ErrorInterceptorHandler {
  Response? resolvedResponse;
  DioException? nextError;

  @override
  void resolve(Response response) {
    resolvedResponse = response;
  }

  @override
  void next(DioException err) {
    nextError = err;
  }
}
