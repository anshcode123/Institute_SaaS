class AttendanceStudentSummary {
  final String id;
  final String firstName;
  final String lastName;
  final String studentCode;

  const AttendanceStudentSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.studentCode,
  });

  String get fullName => '$firstName $lastName';

  factory AttendanceStudentSummary.fromJson(Map<String, dynamic> json) => AttendanceStudentSummary(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        studentCode: json['studentCode'] as String,
      );
}

class AttendanceBatchSummary {
  final String id;
  final String name;
  const AttendanceBatchSummary({required this.id, required this.name});

  factory AttendanceBatchSummary.fromJson(Map<String, dynamic> json) =>
      AttendanceBatchSummary(id: json['id'] as String, name: json['name'] as String);
}

class AttendanceMarkedBy {
  final String id;
  final String name;
  final String role;
  const AttendanceMarkedBy({required this.id, required this.name, required this.role});

  factory AttendanceMarkedBy.fromJson(Map<String, dynamic> json) => AttendanceMarkedBy(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
      );
}

class AttendanceRecord {
  final String id;
  final DateTime date;
  final String status;
  final DateTime markedAt;
  final AttendanceStudentSummary? student;
  final AttendanceBatchSummary? batch;
  final AttendanceMarkedBy? markedBy;

  const AttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    required this.markedAt,
    this.student,
    this.batch,
    this.markedBy,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      markedAt: DateTime.parse(json['markedAt'] as String),
      student: json['student'] != null
          ? AttendanceStudentSummary.fromJson(json['student'] as Map<String, dynamic>)
          : null,
      batch: json['batch'] != null
          ? AttendanceBatchSummary.fromJson(json['batch'] as Map<String, dynamic>)
          : null,
      markedBy: json['markedBy'] != null
          ? AttendanceMarkedBy.fromJson(json['markedBy'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ScanResult {
  final bool alreadyMarked;
  final AttendanceRecord attendance;

  const ScanResult({required this.alreadyMarked, required this.attendance});

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        alreadyMarked: json['alreadyMarked'] as bool,
        attendance: AttendanceRecord.fromJson(json['attendance'] as Map<String, dynamic>),
      );
}

class BatchAttendanceSummary {
  final int totalStudents;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int remaining;
  final double percentage;

  const BatchAttendanceSummary({
    required this.totalStudents,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.remaining,
    required this.percentage,
  });

  factory BatchAttendanceSummary.fromJson(Map<String, dynamic> json) => BatchAttendanceSummary(
        totalStudents: json['totalStudents'] as int,
        present: json['present'] as int,
        absent: json['absent'] as int,
        late: json['late'] as int,
        excused: json['excused'] as int,
        remaining: json['remaining'] as int,
        percentage: (json['percentage'] as num).toDouble(),
      );
}

class StudentAttendanceSummary {
  final int total;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final double percentage;
  final List<AttendanceRecord> recent;

  const StudentAttendanceSummary({
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.percentage,
    required this.recent,
  });

  factory StudentAttendanceSummary.fromJson(Map<String, dynamic> json) => StudentAttendanceSummary(
        total: json['total'] as int,
        present: json['present'] as int,
        absent: json['absent'] as int,
        late: json['late'] as int,
        excused: json['excused'] as int,
        percentage: (json['percentage'] as num).toDouble(),
        recent: (json['recent'] as List)
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
