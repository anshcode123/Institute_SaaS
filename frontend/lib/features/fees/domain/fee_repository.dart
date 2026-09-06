import '../../../core/network/paginated_result.dart';
import 'fee_models.dart';

abstract class FeeRepository {
  // Fee structures
  Future<FeeStructure> createFeeStructure({
    required String name,
    String? description,
    required String feeType,
    double? totalAmount,
    String? courseId,
    String? coursePaymentMode,
    int? monthlyDueDay,
    double? lateFee,
    int? gracePeriodDays,
    String? batchId,
    List<FeeStructureInstallmentTemplate> installments = const [],
    List<MonthlyFeeGroup> monthlyGroups = const [],
  });
  Future<List<FeeStructure>> listFeeStructures(
      {String? status, String? batchId});
  Future<FeeStructure> getFeeStructure(String id);
  Future<FeeStructure> updateFeeStructure(String id, Map<String, dynamic> data);

  // Assigning fees
  Future<StudentFee> assignFee({
    required String studentId,
    required String feeStructureId,
    required DateTime feeStartDate,
    String? monthlyFeeGroupId,
    double? discountAmount,
    double? discountPercentage,
  });
  Future<PaginatedResult<StudentFee>> listStudentFees(
      {String? studentId, String? status, int page = 1});
  Future<StudentFee> getStudentFee(String id);
  Future<StudentFeesResult> getFeesForStudent(String studentId);

  // Dashboard
  Future<FeeDashboardSummary> getDashboard();

  // Payments
  Future<Payment> recordPayment({
    required String studentId,
    required String studentFeeId,
    required String installmentId,
    required double amount,
    required String paymentMethod,
    String? transactionReference,
    DateTime? paymentDate,
    String? notes,
  });
  Future<PaginatedResult<Payment>> listPayments(
      {String? studentId, String? studentFeeId, int page = 1});
  Future<Payment> getPayment(String id);

  // Receipts
  Future<Receipt> getReceipt(String id);
}
