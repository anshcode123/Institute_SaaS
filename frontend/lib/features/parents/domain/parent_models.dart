class StudentSummary {
  final String id;
  final String firstName;
  final String lastName;
  final String relationship;

  const StudentSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.relationship,
  });

  String get fullName => '$firstName $lastName';

  /// Backend returns StudentParent join rows shaped like
  /// { relationship, student: { id, firstName, lastName } }.
  factory StudentSummary.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>;
    return StudentSummary(
      id: student['id'] as String,
      firstName: student['firstName'] as String,
      lastName: student['lastName'] as String,
      relationship: json['relationship'] as String? ?? 'GUARDIAN',
    );
  }
}

class Parent {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String status;
  final List<StudentSummary> students;

  const Parent({
    required this.id,
    required this.name,
    required this.status,
    this.phone,
    this.email,
    this.address,
    this.students = const [],
  });

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      status: json['status'] as String,
      students: json['students'] != null
          ? (json['students'] as List)
              .map((e) => StudentSummary.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}
