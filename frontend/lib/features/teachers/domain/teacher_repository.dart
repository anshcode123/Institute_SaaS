import '../../../core/network/paginated_result.dart';
import 'teacher_models.dart';

abstract class TeacherRepository {
  Future<PaginatedResult<Teacher>> list({String? query, String? status, int page = 1});
  Future<Teacher> getById(String id);
  Future<Teacher> create(Map<String, dynamic> data);
  Future<Teacher> update(String id, Map<String, dynamic> data);
  Future<void> deactivate(String id);
  Future<Teacher> assignBatches(String teacherId, List<String> batchIds);

  /// Creates the login account for an existing teacher (Institute Admin
  /// action). Returns the initial password once - never retrievable again.
  Future<Map<String, dynamic>> createLogin(String teacherId);
}
