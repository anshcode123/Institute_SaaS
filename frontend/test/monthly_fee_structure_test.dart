import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_saas/core/network/dio_client.dart';
import 'package:student_saas/core/storage/secure_storage.dart';
import 'package:student_saas/features/auth/data/auth_storage_keys.dart';
import 'package:student_saas/features/fees/data/fee_repository_impl.dart';
import 'package:student_saas/features/fees/domain/fee_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Interceptor? currentTestInterceptor;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SecureStorage.instance
        .write(AuthStorageKeys.accessToken, 'valid_token_123');
  });

  tearDown(() async {
    if (currentTestInterceptor != null) {
      DioClient().dio.interceptors.remove(currentTestInterceptor);
      currentTestInterceptor = null;
    }
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
      'createFeeStructure sends correct Monthly Subject-wise payload with Bearer header',
      () async {
    final mockDio = DioClient().dio;

    RequestOptions? capturedRequest;
    currentTestInterceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        capturedRequest = options;
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 201,
          data: {
            'success': true,
            'data': {
              'id': 'fee_struct_uuid_1',
              'name': 'Class 10 Subject-wise Fee',
              'description': 'Monthly subject pricing',
              'totalAmount': '1500.00',
              'currency': 'INR',
              'status': 'ACTIVE',
              'feeType': 'MONTHLY',
              'monthlyDueDay': 5,
              'lateFee': '50.00',
              'gracePeriodDays': 3,
              'monthlyGroups': [
                {
                  'id': 'grp_1',
                  'name': 'Science Stream',
                  'applicableLevel': 'Class 10',
                  'pricingType': 'SUBJECT_WISE',
                  'subjectPrices': [
                    {
                      'id': 'sp_1',
                      'subjectId': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
                      'monthlyAmount': '500.00',
                      'subject': {
                        'id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
                        'name': 'Physics'
                      },
                    },
                    {
                      'id': 'sp_2',
                      'subjectId': '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
                      'monthlyAmount': '1000.00',
                      'subject': {
                        'id': '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
                        'name': 'Chemistry'
                      },
                    },
                  ],
                },
              ],
            },
          },
        ));
      },
    );
    mockDio.interceptors.add(currentTestInterceptor!);

    final feeRepo = FeeRepositoryImpl();

    final result = await feeRepo.createFeeStructure(
      name: 'Class 10 Subject-wise Fee',
      description: 'Monthly subject pricing',
      feeType: 'MONTHLY',
      monthlyDueDay: 5,
      lateFee: 50.0,
      gracePeriodDays: 3,
      monthlyGroups: const [
        MonthlyFeeGroup(
          name: 'Science Stream',
          applicableLevel: 'Class 10',
          pricingType: 'SUBJECT_WISE',
          subjects: [
            MonthlyFeeGroupSubject(
              subjectId: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
              monthlyAmount: 500.0,
            ),
            MonthlyFeeGroupSubject(
              subjectId: '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
              monthlyAmount: 1000.0,
            ),
          ],
        ),
      ],
    );

    // Verify request
    expect(capturedRequest, isNotNull);
    expect(capturedRequest!.path, equals('/fees/structures'));
    expect(capturedRequest!.method, equals('POST'));
    expect(capturedRequest!.headers['Authorization'],
        equals('Bearer valid_token_123'));

    final body = capturedRequest!.data as Map<String, dynamic>;
    expect(body['feeType'], equals('MONTHLY'));
    expect(body['monthlyDueDay'], equals(5));
    expect(body['lateFee'], equals('50.00'));
    expect(body['monthlyGroups'], isA<List>());

    final groups = body['monthlyGroups'] as List;
    expect(groups.length, equals(1));
    expect(groups[0]['pricingType'], equals('SUBJECT_WISE'));
    expect(groups[0]['subjects'], isA<List>());

    final subjects = groups[0]['subjects'] as List;
    expect(subjects.length, equals(2));
    expect(subjects[0]['subjectId'],
        equals('7c9e6679-7425-40de-944b-e07fc1f90ae7'));
    expect(subjects[0]['monthlyAmount'], equals('500.00'));

    // Verify parsed response
    expect(result.id, equals('fee_struct_uuid_1'));
    expect(result.feeType, equals('MONTHLY'));
    expect(result.monthlyGroups.length, equals(1));
    expect(result.monthlyGroups[0].pricingType, equals('SUBJECT_WISE'));
    expect(result.monthlyGroups[0].subjects.length, equals(2));
    expect(result.monthlyGroups[0].subjects[0].subjectName, equals('Physics'));
  });

  test(
      'FeeRepositoryImpl formats 400 validation error details into AppException',
      () async {
    final mockDio = DioClient().dio;

    currentTestInterceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        return handler.reject(DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {
              'success': false,
              'message': 'Validation failed',
              'error': {
                'monthlyGroups': ['Invalid uuid']
              },
            },
          ),
        ));
      },
    );
    mockDio.interceptors.add(currentTestInterceptor!);

    final feeRepo = FeeRepositoryImpl();

    expect(
      () => feeRepo.createFeeStructure(
        name: 'Invalid Struct',
        feeType: 'MONTHLY',
        monthlyGroups: const [
          MonthlyFeeGroup(
            name: 'G1',
            applicableLevel: '10',
            pricingType: 'SUBJECT_WISE',
            subjects: [
              MonthlyFeeGroupSubject(
                subjectName: 'Physics',
                monthlyAmount: 100,
              ),
            ],
          ),
        ],
      ),
      throwsA(isA<dynamic>().having(
        (e) => e.toString(),
        'message',
        contains('Validation failed:\nmonthlyGroups: Invalid uuid'),
      )),
    );
  });

  test(
      'createFeeStructure sends subjectName when creating with human-readable subject names',
      () async {
    final mockDio = DioClient().dio;

    RequestOptions? capturedRequest;
    currentTestInterceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        capturedRequest = options;
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 201,
          data: {
            'success': true,
            'data': {
              'id': 'fee_struct_uuid_2',
              'name': 'Class 12 Subject Fee',
              'totalAmount': '1200.00',
              'currency': 'INR',
              'status': 'ACTIVE',
              'feeType': 'MONTHLY',
              'monthlyDueDay': 10,
              'monthlyGroups': [
                {
                  'id': 'grp_2',
                  'name': 'PCM',
                  'applicableLevel': 'Class 12',
                  'pricingType': 'SUBJECT_WISE',
                  'subjectPrices': [
                    {
                      'id': 'sp_10',
                      'subjectId': 'sub_physics_1',
                      'monthlyAmount': '600.00',
                      'subject': {'id': 'sub_physics_1', 'name': 'Physics'},
                    },
                    {
                      'id': 'sp_11',
                      'subjectId': 'sub_chemistry_1',
                      'monthlyAmount': '600.00',
                      'subject': {'id': 'sub_chemistry_1', 'name': 'Chemistry'},
                    },
                  ],
                },
              ],
            },
          },
        ));
      },
    );
    mockDio.interceptors.add(currentTestInterceptor!);

    final feeRepo = FeeRepositoryImpl();

    final result = await feeRepo.createFeeStructure(
      name: 'Class 12 Subject Fee',
      feeType: 'MONTHLY',
      monthlyDueDay: 10,
      monthlyGroups: const [
        MonthlyFeeGroup(
          name: 'PCM',
          applicableLevel: 'Class 12',
          pricingType: 'SUBJECT_WISE',
          subjects: [
            MonthlyFeeGroupSubject(
              subjectName: 'Physics',
              monthlyAmount: 600.0,
            ),
            MonthlyFeeGroupSubject(
              subjectName: 'Chemistry',
              monthlyAmount: 600.0,
            ),
          ],
        ),
      ],
    );

    expect(capturedRequest, isNotNull);
    final body = capturedRequest!.data as Map<String, dynamic>;
    final groups = body['monthlyGroups'] as List;
    final subjects = groups[0]['subjects'] as List;
    expect(subjects[0]['subjectName'], equals('Physics'));
    expect(subjects[1]['subjectName'], equals('Chemistry'));
    expect(result.monthlyGroups[0].subjects[0].subjectName, equals('Physics'));
    expect(
        result.monthlyGroups[0].subjects[1].subjectName, equals('Chemistry'));
  });
}
