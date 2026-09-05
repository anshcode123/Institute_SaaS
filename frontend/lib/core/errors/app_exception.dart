/// Base exception type. Feature-specific exceptions can extend this later
/// once real API calls (beyond health-check) are wired up.
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => 'AppException($statusCode): $message';
}
