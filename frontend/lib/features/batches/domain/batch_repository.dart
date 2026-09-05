import '../../../core/network/paginated_result.dart';
import 'batch_models.dart';

abstract class BatchRepository {
  Future<PaginatedResult<Batch>> list({String? query, String? status, int page = 1});
  Future<Batch> getById(String id);
  Future<Batch> create(Map<String, dynamic> data);
  Future<Batch> update(String id, Map<String, dynamic> data);
  Future<void> deactivate(String id);
  Future<Batch> addStudents(String batchId, List<String> studentIds);
  Future<Batch> removeStudents(String batchId, List<String> studentIds);
  Future<Batch> assignTeachers(String batchId, List<String> teacherIds);
}
