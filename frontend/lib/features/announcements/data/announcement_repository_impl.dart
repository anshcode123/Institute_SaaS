import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/announcement_models.dart';

/// One repository, two use cases: Institute Admin CRUD (/announcements)
/// and the read-only portal views (/student/announcements,
/// /parent/children/:id/announcements) - the portal methods just hit a
/// different, already role-scoped, endpoint.
class AnnouncementRepository {
  final Dio _dio = DioClient().dio;

  Future<List<Announcement>> listForAdmin() async {
    final response = await _dio.get('/announcements');
    final items = (response.data as Map<String, dynamic>)['data']['items'] as List;
    return items.map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Announcement>> listForStudent() async {
    final response = await _dio.get('/student/announcements');
    final items = (response.data as Map<String, dynamic>)['data'] as List;
    return items.map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Announcement>> listForChild(String studentId) async {
    final response = await _dio.get('/parent/children/$studentId/announcements');
    final items = (response.data as Map<String, dynamic>)['data'] as List;
    return items.map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Announcement> create({
    required String title,
    required String message,
    required String audience,
    String? batchId,
  }) async {
    final response = await _dio.post('/announcements', data: {
      'title': title,
      'message': message,
      'audience': audience,
      if (batchId != null) 'batchId': batchId,
    });
    return Announcement.fromJson((response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<Announcement> updateStatus(String id, String status) async {
    final response = await _dio.patch('/announcements/$id', data: {'status': status});
    return Announcement.fromJson((response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }
}
