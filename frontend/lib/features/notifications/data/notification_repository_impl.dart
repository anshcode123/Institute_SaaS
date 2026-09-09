import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/notification_models.dart';

class NotificationRepository {
  final Dio _dio = DioClient().dio;

  Future<NotificationsPage> list({bool unreadOnly = false}) async {
    final response = await _dio.get('/notifications', queryParameters: {
      if (unreadOnly) 'unreadOnly': true,
    });
    return NotificationsPage.fromJson((response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<void> markRead(String id) => _dio.post('/notifications/$id/read');

  Future<void> markAllRead() => _dio.post('/notifications/read-all');
}
