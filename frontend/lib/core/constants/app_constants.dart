class AppConstants {
  AppConstants._();

  static const String appName = 'Student SaaS';

  // Base URL for the backend API. Swap per environment later
  // (e.g. via --dart-define or flavors) once auth/env handling is added.
  static const String apiBaseUrl = 'http://localhost:4000/api';
}
