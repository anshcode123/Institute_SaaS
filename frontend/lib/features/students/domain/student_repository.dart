import '../../../core/network/paginated_result.dart';
import 'student_models.dart';

abstract class StudentRepository {
  Future<PaginatedResult<Student>> list(
      {String? query, String? status, String? batchId, int page = 1});

  Future<Student> getById(String id);

  Future<Student> create(Map<String, dynamic> data);

  Future<Student> update(String id, Map<String, dynamic> data);

  Future<void> deactivate(String id);

  Future<void> linkParent(String studentId, String parentId,
      {String? relationship});

  Future<void> unlinkParent(String studentId, String parentId);

  Future<Student> assignBatch(String studentId, String batchId);

  Future<Map<String, dynamic>> createLogin(String studentId,
      {String? loginId, String? password});

  Future<Map<String, dynamic>> resetPassword(String studentId,
      {String? newPassword});
}
