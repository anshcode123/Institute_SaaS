import '../../../core/network/paginated_result.dart';
import 'test_models.dart';

abstract class TestRepository {
  Future<Test> createTest({
    required String batchId,
    required String name,
    String? description,
    required DateTime testDate,
    int? durationMinutes,
    required int passingMarks,
    required List<Map<String, dynamic>> subjects,
  });
  Future<PaginatedResult<Test>> listTests({String? batchId, String? status, int page = 1});
  Future<Test> getTest(String id);
  Future<Test> updateTest(String id, Map<String, dynamic> data);
  Future<void> cancelTest(String id);

  Future<Test> addTestSubject(String testId, {required String subjectId, required int maxMarks, required int passingMarks});
  Future<Test> updateTestSubject(String testId, String testSubjectId, Map<String, dynamic> data);
  Future<Test> removeTestSubject(String testId, String testSubjectId);

  Future<List<StudentSubjectMark>> saveMarks({
    required String testId,
    required String subjectId,
    required List<Map<String, dynamic>> entries,
  });
  Future<List<StudentSubjectMark>> listMarks(String testId, {String? subjectId});

  Future<TestResultsPage> getTestResults(String testId);
  Future<Test> publishTest(String testId);
  Future<Test> unpublishTest(String testId);

  Future<List<StudentTestResult>> getStudentResults(String studentId);
  Future<StudentResultDetail> getStudentResultDetail(String studentId, String resultId);
}
