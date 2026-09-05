class SubjectSummary {
  final String id;
  final String name;
  const SubjectSummary({required this.id, required this.name});

  factory SubjectSummary.fromJson(Map<String, dynamic> json) =>
      SubjectSummary(id: json['id'] as String, name: json['name'] as String);
}

class TestSubjectConfig {
  final String id;
  final SubjectSummary subject;
  final int maxMarks;
  final int passingMarks;

  const TestSubjectConfig({
    required this.id,
    required this.subject,
    required this.maxMarks,
    required this.passingMarks,
  });

  factory TestSubjectConfig.fromJson(Map<String, dynamic> json) => TestSubjectConfig(
        id: json['id'] as String,
        subject: SubjectSummary.fromJson(json['subject'] as Map<String, dynamic>),
        maxMarks: json['maxMarks'] as int,
        passingMarks: json['passingMarks'] as int,
      );
}

class TestBatchSummary {
  final String id;
  final String name;
  const TestBatchSummary({required this.id, required this.name});

  factory TestBatchSummary.fromJson(Map<String, dynamic> json) =>
      TestBatchSummary(id: json['id'] as String, name: json['name'] as String);
}

class Test {
  final String id;
  final String name;
  final String? description;
  final DateTime testDate;
  final int? durationMinutes;
  final int totalMarks;
  final int passingMarks;
  final String status;
  final TestBatchSummary? batch;
  final List<TestSubjectConfig> subjects;
  final int? resultCount;

  const Test({
    required this.id,
    required this.name,
    required this.testDate,
    required this.totalMarks,
    required this.passingMarks,
    required this.status,
    this.description,
    this.durationMinutes,
    this.batch,
    this.subjects = const [],
    this.resultCount,
  });

  factory Test.fromJson(Map<String, dynamic> json) => Test(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        testDate: DateTime.parse(json['testDate'] as String),
        durationMinutes: json['durationMinutes'] as int?,
        totalMarks: json['totalMarks'] as int,
        passingMarks: json['passingMarks'] as int,
        status: json['status'] as String,
        batch: json['batch'] != null ? TestBatchSummary.fromJson(json['batch'] as Map<String, dynamic>) : null,
        subjects: json['subjects'] != null
            ? (json['subjects'] as List).map((e) => TestSubjectConfig.fromJson(e as Map<String, dynamic>)).toList()
            : const [],
        resultCount: json['_count'] != null ? (json['_count']['results'] as int?) : null,
      );
}

class StudentSummaryForMarks {
  final String id;
  final String firstName;
  final String lastName;
  final String studentCode;

  const StudentSummaryForMarks({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.studentCode,
  });

  String get fullName => '$firstName $lastName';

  factory StudentSummaryForMarks.fromJson(Map<String, dynamic> json) => StudentSummaryForMarks(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        studentCode: json['studentCode'] as String,
      );
}

class StudentSubjectMark {
  final String id;
  final StudentSummaryForMarks student;
  final SubjectSummary subject;
  final int maxMarks;
  final int obtainedMarks;

  const StudentSubjectMark({
    required this.id,
    required this.student,
    required this.subject,
    required this.maxMarks,
    required this.obtainedMarks,
  });

  factory StudentSubjectMark.fromJson(Map<String, dynamic> json) => StudentSubjectMark(
        id: json['id'] as String,
        student: StudentSummaryForMarks.fromJson(json['student'] as Map<String, dynamic>),
        subject: SubjectSummary.fromJson(json['subject'] as Map<String, dynamic>),
        maxMarks: json['maxMarks'] as int,
        obtainedMarks: json['obtainedMarks'] as int,
      );
}

class StudentTestResult {
  final String id;
  final int totalMarks;
  final int obtainedMarks;
  final double percentage;
  final String grade;
  final String status;
  final DateTime? publishedAt;
  final int? rank;
  final StudentSummaryForMarks? student;

  const StudentTestResult({
    required this.id,
    required this.totalMarks,
    required this.obtainedMarks,
    required this.percentage,
    required this.grade,
    required this.status,
    this.publishedAt,
    this.rank,
    this.student,
  });

  factory StudentTestResult.fromJson(Map<String, dynamic> json) => StudentTestResult(
        id: json['id'] as String,
        totalMarks: json['totalMarks'] as int,
        obtainedMarks: json['obtainedMarks'] as int,
        percentage: num.parse(json['percentage'].toString()).toDouble(),
        grade: json['grade'] as String,
        status: json['status'] as String,
        publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt'] as String) : null,
        rank: json['rank'] as int?,
        student: json['student'] != null
            ? StudentSummaryForMarks.fromJson(json['student'] as Map<String, dynamic>)
            : null,
      );
}

class TestResultsSummary {
  final int studentCount;
  final double average;
  final int highest;
  final int lowest;
  final int passCount;
  final int failCount;
  final double passPercentage;

  const TestResultsSummary({
    required this.studentCount,
    required this.average,
    required this.highest,
    required this.lowest,
    required this.passCount,
    required this.failCount,
    required this.passPercentage,
  });

  factory TestResultsSummary.fromJson(Map<String, dynamic> json) => TestResultsSummary(
        studentCount: json['studentCount'] as int,
        average: num.parse(json['average'].toString()).toDouble(),
        highest: json['highest'] as int,
        lowest: json['lowest'] as int,
        passCount: json['passCount'] as int,
        failCount: json['failCount'] as int,
        passPercentage: num.parse(json['passPercentage'].toString()).toDouble(),
      );
}

class TestResultsPage {
  final List<StudentTestResult> results;
  final TestResultsSummary summary;

  const TestResultsPage({required this.results, required this.summary});

  factory TestResultsPage.fromJson(Map<String, dynamic> json) => TestResultsPage(
        results: (json['results'] as List).map((e) => StudentTestResult.fromJson(e as Map<String, dynamic>)).toList(),
        summary: TestResultsSummary.fromJson(json['summary'] as Map<String, dynamic>),
      );
}

/// Full breakdown for one student's one result - test + subject marks +
/// totals. Used by both the Institute Admin/Teacher result view and the
/// Student Profile "Tests" card.
class StudentResultDetail {
  final StudentTestResult result;
  final String testName;
  final DateTime testDate;
  final String batchName;
  final List<StudentSubjectMark> subjectMarks;

  const StudentResultDetail({
    required this.result,
    required this.testName,
    required this.testDate,
    required this.batchName,
    required this.subjectMarks,
  });

  factory StudentResultDetail.fromJson(Map<String, dynamic> json) {
    final test = json['test'] as Map<String, dynamic>;
    return StudentResultDetail(
      result: StudentTestResult.fromJson(json),
      testName: test['name'] as String,
      testDate: DateTime.parse(test['testDate'] as String),
      batchName: test['batch'] != null ? (test['batch']['name'] as String? ?? '') : '',
      subjectMarks: json['subjectMarks'] != null
          ? (json['subjectMarks'] as List)
              .map((e) => StudentSubjectMark.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}
