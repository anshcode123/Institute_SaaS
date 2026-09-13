/// All money fields arrive from the backend as decimal strings (e.g.
/// "60000.00"), never floats - parsed here with `num.parse` only for
/// display formatting. The backend remains the source of truth for every
/// calculation; this app never recomputes totals/discounts/balances.
class FeeStructureInstallmentTemplate {
  final String? id;
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;

  const FeeStructureInstallmentTemplate({
    this.id,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
  });

  factory FeeStructureInstallmentTemplate.fromJson(Map<String, dynamic> json) =>
      FeeStructureInstallmentTemplate(
        id: json['id'] as String?,
        installmentNumber: json['installmentNumber'] as int,
        amount: num.parse(json['amount'].toString()).toDouble(),
        dueDate: DateTime.parse(json['dueDate'] as String),
      );

  Map<String, dynamic> toJson() => {
        'installmentNumber': installmentNumber,
        'amount': amount.toStringAsFixed(2),
        'dueDate': dueDate.toIso8601String().split('T').first,
      };
}

class FeeStructure {
  final String id;
  final String name;
  final String? description;
  final double totalAmount;
  final String currency;
  final String status;
  final String feeType;
  final String? coursePaymentMode;
  final int? monthlyDueDay;
  final double lateFee;
  final int? gracePeriodDays;
  final String? batchId;
  final String? batchName;
  final List<FeeStructureInstallmentTemplate> installments;
  final List<MonthlyFeeGroup> monthlyGroups;

  const FeeStructure({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.feeType,
    this.coursePaymentMode,
    this.monthlyDueDay,
    this.lateFee = 0,
    this.gracePeriodDays,
    this.description,
    this.batchId,
    this.batchName,
    this.installments = const [],
    this.monthlyGroups = const [],
  });

  factory FeeStructure.fromJson(Map<String, dynamic> json) => FeeStructure(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        totalAmount: num.parse(json['totalAmount'].toString()).toDouble(),
        currency: json['currency'] as String? ?? 'INR',
        status: json['status'] as String,
        feeType: json['feeType'] as String? ?? 'MONTHLY',
        coursePaymentMode: json['coursePaymentMode'] as String?,
        monthlyDueDay: json['monthlyDueDay'] as int?,
        lateFee: num.parse(json['lateFee']?.toString() ?? '0').toDouble(),
        gracePeriodDays: json['gracePeriodDays'] as int?,
        batchId: json['batchId'] as String?,
        batchName:
            json['batch'] != null ? (json['batch']['name'] as String?) : null,
        installments: json['installments'] != null
            ? (json['installments'] as List)
                .map((e) => FeeStructureInstallmentTemplate.fromJson(
                    e as Map<String, dynamic>))
                .toList()
            : const [],
        monthlyGroups: json['monthlyGroups'] != null
            ? (json['monthlyGroups'] as List)
                .map((e) => MonthlyFeeGroup.fromJson(e as Map<String, dynamic>))
                .toList()
            : const [],
      );
}

class MonthlyFeeGroupSubject {
  final String? subjectId;
  final String? subjectName;
  final double monthlyAmount;

  const MonthlyFeeGroupSubject({
    this.subjectId,
    this.subjectName,
    required this.monthlyAmount,
  });

  String get displayName => subjectName ?? subjectId ?? 'Subject';

  factory MonthlyFeeGroupSubject.fromJson(Map<String, dynamic> json) =>
      MonthlyFeeGroupSubject(
        subjectId: json['subjectId'] as String?,
        subjectName:
            (json['subject'] as Map<String, dynamic>?)?['name'] as String? ??
                json['subjectName'] as String?,
        monthlyAmount: num.parse(json['monthlyAmount'].toString()).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (subjectId != null && subjectId!.isNotEmpty) 'subjectId': subjectId,
        if (subjectName != null && subjectName!.isNotEmpty)
          'subjectName': subjectName,
        'monthlyAmount': monthlyAmount.toStringAsFixed(2),
      };
}

class MonthlyFeeGroup {
  final String? id;
  final String name;
  final String applicableLevel;
  final String pricingType;
  final double? combinedAmount;
  final List<MonthlyFeeGroupSubject> subjects;
  const MonthlyFeeGroup(
      {this.id,
      required this.name,
      required this.applicableLevel,
      required this.pricingType,
      this.combinedAmount,
      this.subjects = const []});
  double get monthlyTotal => pricingType == 'COMBINED'
      ? combinedAmount ?? 0
      : subjects.fold(0, (sum, subject) => sum + subject.monthlyAmount);
  factory MonthlyFeeGroup.fromJson(Map<String, dynamic> json) =>
      MonthlyFeeGroup(
        id: json['id'] as String?,
        name: json['name'] as String,
        applicableLevel: json['applicableLevel'] as String,
        pricingType: json['pricingType'] as String,
        combinedAmount: json['combinedAmount'] == null
            ? null
            : num.parse(json['combinedAmount'].toString()).toDouble(),
        subjects: json['subjectPrices'] == null
            ? const []
            : (json['subjectPrices'] as List)
                .map((e) =>
                    MonthlyFeeGroupSubject.fromJson(e as Map<String, dynamic>))
                .toList(),
      );
  Map<String, dynamic> toJson() => {
        'name': name,
        'applicableLevel': applicableLevel,
        'pricingType': pricingType,
        if (pricingType == 'COMBINED')
          'combinedAmount': combinedAmount?.toStringAsFixed(2),
        if (pricingType == 'SUBJECT_WISE')
          'subjects': subjects.map((subject) => subject.toJson()).toList()
      };
}

class FeeInstallment {
  final String id;
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final double paidAmount;
  final String status;

  const FeeInstallment({
    required this.id,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    required this.paidAmount,
    required this.status,
  });

  double get remaining => amount - paidAmount;

  factory FeeInstallment.fromJson(Map<String, dynamic> json) => FeeInstallment(
        id: json['id'] as String,
        installmentNumber: json['installmentNumber'] as int,
        amount: num.parse(json['amount'].toString()).toDouble(),
        dueDate: DateTime.parse(json['dueDate'] as String),
        paidAmount: num.parse(json['paidAmount'].toString()).toDouble(),
        status: json['status'] as String,
      );
}

class StudentFeeStudentSummary {
  final String id;
  final String firstName;
  final String lastName;
  final String studentCode;

  const StudentFeeStudentSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.studentCode,
  });

  String get fullName => '$firstName $lastName';

  factory StudentFeeStudentSummary.fromJson(Map<String, dynamic> json) =>
      StudentFeeStudentSummary(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        studentCode: json['studentCode'] as String,
      );
}

class StudentFee {
  final String id;
  final String studentId;
  final String feeStructureId;
  final String feeStructureName;
  final String currency;
  final double totalAmount;
  final String discountType;
  final double discountAmount;
  final double finalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final String status;
  final List<FeeInstallment> installments;
  final StudentFeeStudentSummary? student;
  final DateTime? nextDueDate;
  final String? dueStatusText;

  const StudentFee({
    required this.id,
    required this.studentId,
    required this.feeStructureId,
    required this.feeStructureName,
    required this.currency,
    required this.totalAmount,
    required this.discountType,
    required this.discountAmount,
    required this.finalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.status,
    this.installments = const [],
    this.student,
    this.nextDueDate,
    this.dueStatusText,
  });

  factory StudentFee.fromJson(Map<String, dynamic> json) => StudentFee(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        feeStructureId: json['feeStructureId'] as String,
        feeStructureName: json['feeStructure'] != null
            ? (json['feeStructure']['name'] as String? ?? '')
            : '',
        currency: json['feeStructure'] != null
            ? (json['feeStructure']['currency'] as String? ?? 'INR')
            : 'INR',
        totalAmount: num.parse(json['totalAmount'].toString()).toDouble(),
        discountType: json['discountType'] as String? ?? 'NONE',
        discountAmount: num.parse(json['discountAmount'].toString()).toDouble(),
        finalAmount: num.parse(json['finalAmount'].toString()).toDouble(),
        paidAmount: num.parse(json['paidAmount'].toString()).toDouble(),
        outstandingAmount:
            num.parse(json['outstandingAmount'].toString()).toDouble(),
        status: json['status'] as String,
        installments: json['installments'] != null
            ? (json['installments'] as List)
                .map((e) => FeeInstallment.fromJson(e as Map<String, dynamic>))
                .toList()
            : const [],
        student: json['student'] != null
            ? StudentFeeStudentSummary.fromJson(
                json['student'] as Map<String, dynamic>)
            : null,
        nextDueDate: json['nextDueDate'] != null
            ? DateTime.tryParse(json['nextDueDate'].toString())
            : null,
        dueStatusText: json['dueStatusText'] as String?,
      );
}

class StudentFeesSummary {
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final double paidAmount;
  final double outstandingAmount;

  const StudentFeesSummary({
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
  });

  factory StudentFeesSummary.fromJson(Map<String, dynamic> json) =>
      StudentFeesSummary(
        totalAmount: num.parse(json['totalAmount'].toString()).toDouble(),
        discountAmount: num.parse(json['discountAmount'].toString()).toDouble(),
        finalAmount: num.parse(json['finalAmount'].toString()).toDouble(),
        paidAmount: num.parse(json['paidAmount'].toString()).toDouble(),
        outstandingAmount:
            num.parse(json['outstandingAmount'].toString()).toDouble(),
      );
}

class StudentFeesResult {
  final List<StudentFee> fees;
  final StudentFeesSummary summary;

  const StudentFeesResult({required this.fees, required this.summary});

  factory StudentFeesResult.fromJson(Map<String, dynamic> json) =>
      StudentFeesResult(
        fees: (json['fees'] as List)
            .map((e) => StudentFee.fromJson(e as Map<String, dynamic>))
            .toList(),
        summary: StudentFeesSummary.fromJson(
            json['summary'] as Map<String, dynamic>),
      );
}

class Payment {
  final String id;
  final double amount;
  final String paymentMethod;
  final String? transactionReference;
  final DateTime paymentDate;
  final String? notes;
  final String status;
  final StudentFeeStudentSummary? student;
  final String? receivedByName;
  final String? receiptId;
  final String? receiptNumber;
  final int? installmentNumber;

  const Payment({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.status,
    this.transactionReference,
    this.notes,
    this.student,
    this.receivedByName,
    this.receiptId,
    this.receiptNumber,
    this.installmentNumber,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        amount: num.parse(json['amount'].toString()).toDouble(),
        paymentMethod: json['paymentMethod'] as String,
        transactionReference: json['transactionReference'] as String?,
        paymentDate: DateTime.parse(json['paymentDate'] as String),
        notes: json['notes'] as String?,
        status: json['status'] as String,
        student: json['student'] != null
            ? StudentFeeStudentSummary.fromJson(
                json['student'] as Map<String, dynamic>)
            : null,
        receivedByName: json['receivedBy'] != null
            ? (json['receivedBy']['name'] as String?)
            : null,
        receiptId:
            json['receipt'] != null ? (json['receipt']['id'] as String?) : null,
        receiptNumber: json['receipt'] != null
            ? (json['receipt']['receiptNumber'] as String?)
            : null,
        installmentNumber: json['installment'] != null
            ? (json['installment']['installmentNumber'] as int?)
            : null,
      );
}

class Receipt {
  final String id;
  final String receiptNumber;
  final DateTime issuedAt;
  final double previousOutstanding;
  final double remainingOutstanding;
  final String instituteName;
  final String instituteCode;
  final String studentName;
  final String studentCode;
  final String? parentName;
  final String feeStructureName;
  final int installmentNumber;
  final double amountPaid;
  final String paymentMethod;
  final String? transactionReference;
  final DateTime paymentDate;
  final String receivedByName;

  const Receipt({
    required this.id,
    required this.receiptNumber,
    required this.issuedAt,
    required this.previousOutstanding,
    required this.remainingOutstanding,
    required this.instituteName,
    required this.instituteCode,
    required this.studentName,
    required this.studentCode,
    required this.feeStructureName,
    required this.installmentNumber,
    required this.amountPaid,
    required this.paymentMethod,
    required this.paymentDate,
    required this.receivedByName,
    this.parentName,
    this.transactionReference,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>;
    final student = payment['student'] as Map<String, dynamic>;
    final institute = json['institute'] as Map<String, dynamic>;
    final studentFee = payment['studentFee'] as Map<String, dynamic>;
    final feeStructure = studentFee['feeStructure'] as Map<String, dynamic>;
    final installment = payment['installment'] as Map<String, dynamic>;
    final receivedBy = payment['receivedBy'] as Map<String, dynamic>;

    return Receipt(
      id: json['id'] as String,
      receiptNumber: json['receiptNumber'] as String,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      previousOutstanding:
          num.parse(json['previousOutstanding'].toString()).toDouble(),
      remainingOutstanding:
          num.parse(json['remainingOutstanding'].toString()).toDouble(),
      instituteName: institute['name'] as String,
      instituteCode: institute['instituteCode'] as String,
      studentName: '${student['firstName']} ${student['lastName']}',
      studentCode: student['studentCode'] as String,
      parentName: json['parentName'] as String?,
      feeStructureName: feeStructure['name'] as String,
      installmentNumber: installment['installmentNumber'] as int,
      amountPaid: num.parse(payment['amount'].toString()).toDouble(),
      paymentMethod: payment['paymentMethod'] as String,
      transactionReference: payment['transactionReference'] as String?,
      paymentDate: DateTime.parse(payment['paymentDate'] as String),
      receivedByName: receivedBy['name'] as String,
    );
  }
}

class FeeDashboardSummary {
  final double totalFees;
  final double collected;
  final double outstanding;
  final double overdue;

  const FeeDashboardSummary({
    required this.totalFees,
    required this.collected,
    required this.outstanding,
    required this.overdue,
  });

  factory FeeDashboardSummary.fromJson(Map<String, dynamic> json) =>
      FeeDashboardSummary(
        totalFees: num.parse(json['totalFees'].toString()).toDouble(),
        collected: num.parse(json['collected'].toString()).toDouble(),
        outstanding: num.parse(json['outstanding'].toString()).toDouble(),
        overdue: num.parse(json['overdue'].toString()).toDouble(),
      );
}
