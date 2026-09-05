class TeacherSummary {
  final String id;
  final String name;
  const TeacherSummary({required this.id, required this.name});

  factory TeacherSummary.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacher'] as Map<String, dynamic>;
    return TeacherSummary(id: teacher['id'] as String, name: teacher['name'] as String);
  }
}

class BatchStudent {
  final String id;
  final String firstName;
  final String lastName;
  const BatchStudent({required this.id, required this.firstName, required this.lastName});

  String get fullName => '$firstName $lastName';

  factory BatchStudent.fromJson(Map<String, dynamic> json) => BatchStudent(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
      );
}

class Batch {
  final String id;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final List<TeacherSummary> teachers;
  final List<BatchStudent> students;
  final int? studentCount;

  const Batch({
    required this.id,
    required this.name,
    required this.status,
    this.description,
    this.startDate,
    this.endDate,
    this.teachers = const [],
    this.students = const [],
    this.studentCount,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      status: json['status'] as String,
      teachers: json['teachers'] != null
          ? (json['teachers'] as List).map((e) => TeacherSummary.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
      students: json['students'] != null
          ? (json['students'] as List).map((e) => BatchStudent.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
      studentCount: json['_count'] != null ? (json['_count']['students'] as int?) : null,
    );
  }
}
