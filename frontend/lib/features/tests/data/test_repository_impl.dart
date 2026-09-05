import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/test_models.dart';
import '../domain/test_repository.dart';

class TestRepositoryImpl implements TestRepository {
  final Dio _dio = DioClient().dio;

  String _dateOnly(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  @override
  Future<Test> createTest({
    required String batchId,
    required String name,
    String? description,
    required DateTime testDate,
    int? durationMinutes,
    required int passingMarks,
    required List<Map<String, dynamic>> subjects,
  }) async {
    final data = await _send('POST', '/tests', {
      'batchId': batchId,
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      'testDate': _dateOnly(testDate),
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      'passingMarks': passingMarks,
      'subjects': subjects,
    });
    return Test.fromJson(data);
  }

  @override
  Future<PaginatedResult<Test>> listTests({String? batchId, String? status, int page = 1}) async {
    final data = await _get('/tests', queryParameters: {
      if (batchId != null) 'batchId': batchId,
      if (status != null) 'status': status,
      'page': page,
    });
    return PaginatedResult.fromJson(data, Test.fromJson);
  }

  @override
  Future<Test> getTest(String id) async => Test.fromJson(await _get('/tests/$id'));

  @override
  Future<Test> updateTest(String id, Map<String, dynamic> data) async =>
      Test.fromJson(await _send('PATCH', '/tests/$id', data));

  @override
  Future<void> cancelTest(String id) => _send('DELETE', '/tests/$id', null);

  @override
  Future<Test> addTestSubject(
    String testId, {
    required String subjectId,
    required int maxMarks,
    required int passingMarks,
  }) async {
    final data = await _send('POST', '/tests/$testId/subjects', {
      'subjectId': subjectId,
      'maxMarks': maxMarks,
      'passingMarks': passingMarks,
    });
    return Test.fromJson(data);
  }

  @override
  Future<Test> updateTestSubject(String testId, String testSubjectId, Map<String, dynamic> data) async {
    final result = await _send('PATCH', '/tests/$testId/subjects/$testSubjectId', data);
    return Test.fromJson(result);
  }

  @override
  Future<Test> removeTestSubject(String testId, String testSubjectId) async {
    final result = await _send('DELETE', '/tests/$testId/subjects/$testSubjectId', null);
    return Test.fromJson(result);
  }

  @override
  Future<List<StudentSubjectMark>> saveMarks({
    required String testId,
    required String subjectId,
    required List<Map<String, dynamic>> entries,
  }) async {
    final response = await _dio.post('/tests/$testId/marks', data: {
      'subjectId': subjectId,
      'entries': entries,
    });
    final list = (response.data as Map<String, dynamic>)['data'] as List;
    return list.map((e) => StudentSubjectMark.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<StudentSubjectMark>> listMarks(String testId, {String? subjectId}) async {
    final response = await _dio.get('/tests/$testId/marks', queryParameters: {
      if (subjectId != null) 'subjectId': subjectId,
    });
    final list = (response.data as Map<String, dynamic>)['data'] as List;
    return list.map((e) => StudentSubjectMark.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<TestResultsPage> getTestResults(String testId) async {
    final data = await _get('/tests/$testId/results');
    return TestResultsPage.fromJson(data);
  }

  @override
  Future<Test> publishTest(String testId) async => Test.fromJson(await _send('POST', '/tests/$testId/publish', null));

  @override
  Future<Test> unpublishTest(String testId) async =>
      Test.fromJson(await _send('POST', '/tests/$testId/unpublish', null));

  @override
  Future<List<StudentTestResult>> getStudentResults(String studentId) async {
    final response = await _dio.get('/students/$studentId/results');
    final list = (response.data as Map<String, dynamic>)['data'] as List;
    return list.map((e) => StudentTestResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<StudentResultDetail> getStudentResultDetail(String studentId, String resultId) async {
    final data = await _get('/students/$studentId/results/$resultId');
    return StudentResultDetail.fromJson(data);
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
