class Batch {
  final String id;
  final String name;

  const Batch({required this.id, required this.name});

  factory Batch.fromJson(Map<String, dynamic> json) =>
      Batch(id: json['id'] as String, name: json['name'] as String);
}

class ParentSummary {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String relationship;

  const ParentSummary({
    required this.id,
    required this.name,
    required this.relationship,
    this.phone,
    this.email,
  });

  /// Backend returns StudentParent join rows shaped like
  /// { relationship, parent: { id, name, phone, email } }.
  factory ParentSummary.fromJson(Map<String, dynamic> json) {
    final parent = json['parent'] as Map<String, dynamic>;
    return ParentSummary(
      id: parent['id'] as String,
      name: parent['name'] as String,
      phone: parent['phone'] as String?,
      email: parent['email'] as String?,
      relationship: json['relationship'] as String? ?? 'GUARDIAN',
    );
  }
}

class Student {
  final String id;
  final String studentCode;
  final String firstName;
  final String lastName;
  final String? profilePhoto;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime admissionDate;
  final String status;
  final Batch? batch;
  final List<ParentSummary> parents;
  final String? qrCode;

  const Student({
    required this.id,
    required this.studentCode,
    required this.firstName,
    required this.lastName,
    required this.admissionDate,
    required this.status,
    this.profilePhoto,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.email,
    this.address,
    this.batch,
    this.parents = const [],
    this.qrCode,
  });

  String get fullName => '$firstName $lastName';

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      studentCode: json['studentCode'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      profilePhoto: json['profilePhoto'] as String?,
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth'] as String) : null,
      gender: json['gender'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      admissionDate: DateTime.parse(json['admissionDate'] as String),
      status: json['status'] as String,
      batch: json['batch'] != null ? Batch.fromJson(json['batch'] as Map<String, dynamic>) : null,
      parents: json['parents'] != null
          ? (json['parents'] as List)
              .map((e) => ParentSummary.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      qrCode: json['qrCode'] as String?,
    );
  }
}
