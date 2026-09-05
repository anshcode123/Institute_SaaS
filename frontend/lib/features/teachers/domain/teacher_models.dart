class BatchSummary {
  final String id;
  final String name;
  const BatchSummary({required this.id, required this.name});

  /// Backend returns TeacherBatch join rows shaped like { batch: {id,name} }.
  factory BatchSummary.fromJson(Map<String, dynamic> json) {
    final batch = json['batch'] as Map<String, dynamic>;
    return BatchSummary(id: batch['id'] as String, name: batch['name'] as String);
  }
}

class SubjectSummary {
  final String id;
  final String name;
  const SubjectSummary({required this.id, required this.name});

  /// Backend returns TeacherSubject join rows shaped like { subject: {id,name} }.
  factory SubjectSummary.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'] as Map<String, dynamic>;
    return SubjectSummary(id: subject['id'] as String, name: subject['name'] as String);
  }
}

class Teacher {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? profilePhoto;
  final String? address;
  final DateTime joiningDate;
  final String status;
  final List<BatchSummary> batches;
  final List<SubjectSummary> subjects;
  final bool hasLogin;

  const Teacher({
    required this.id,
    required this.name,
    required this.joiningDate,
    required this.status,
    this.phone,
    this.email,
    this.profilePhoto,
    this.address,
    this.batches = const [],
    this.subjects = const [],
    this.hasLogin = false,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
      address: json['address'] as String?,
      joiningDate: DateTime.parse(json['joiningDate'] as String),
      status: json['status'] as String,
      batches: json['batches'] != null
          ? (json['batches'] as List).map((e) => BatchSummary.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
      subjects: json['subjects'] != null
          ? (json['subjects'] as List).map((e) => SubjectSummary.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
      // Backend's Teacher record includes a nullable userId scalar (the
      // link to a login account) alongside the batches/subjects relations.
      hasLogin: json['userId'] != null,
    );
  }
}
