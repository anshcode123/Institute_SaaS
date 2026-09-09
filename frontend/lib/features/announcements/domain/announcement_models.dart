class Announcement {
  final String id;
  final String title;
  final String message;
  final String audience;
  final String status;
  final DateTime? publishedAt;
  final DateTime? expiresAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.audience,
    required this.status,
    this.publishedAt,
    this.expiresAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        audience: json['audience'] as String,
        status: json['status'] as String,
        publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt'] as String) : null,
        expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
      );
}
