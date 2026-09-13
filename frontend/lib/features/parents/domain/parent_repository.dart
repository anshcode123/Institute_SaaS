import '../../../core/network/paginated_result.dart';
import 'parent_models.dart';

abstract class ParentRepository {
  Future<PaginatedResult<Parent>> list(
      {String? query, String? status, int page = 1});
  Future<Parent> getById(String id);
  Future<Parent> create(Map<String, dynamic> data);
  Future<Parent> update(String id, Map<String, dynamic> data);
  Future<void> deactivate(String id);
  Future<Map<String, dynamic>> createLogin(String parentId,
      {String? loginId, String? password});
  Future<Map<String, dynamic>> resetPassword(String parentId,
      {String? newPassword});
}
