enum InstituteStatus { active, suspended }

InstituteStatus instituteStatusFromJson(String value) {
  return value.toUpperCase() == 'SUSPENDED'
      ? InstituteStatus.suspended
      : InstituteStatus.active;
}

class Institute {
  const Institute({
    required this.id,
    required this.instituteCode,
    required this.name,
    required this.email,
    required this.status,
    this.phone,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String instituteCode;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final InstituteStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Institute.fromJson(Map<String, dynamic> json) => Institute(
        id: json['id'] as String,
        instituteCode: json['instituteCode'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        status: instituteStatusFromJson(json['status'] as String? ?? 'ACTIVE'),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
}

class InstituteCreationResult {
  const InstituteCreationResult({
    required this.institute,
    required this.instituteCode,
    required this.initialPassword,
  });

  final Institute institute;
  final String instituteCode;
  final String initialPassword;
}
