import 'package:dio/dio.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/fee_models.dart';
import '../domain/fee_repository.dart';

class FeeRepositoryImpl implements FeeRepository {
  final Dio _dio = DioClient().dio;

  @override
  Future<FeeStructure> createFeeStructure({
    required String name,
    String? description,
    required double totalAmount,
    String? batchId,
    required String feeType,
    String? coursePaymentMode,
    required List<FeeStructureInstallmentTemplate> installments,
  }) async {
    final data = await _send('POST', '/fees/structures', {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      'totalAmount': totalAmount.toStringAsFixed(2),
      if (batchId != null) 'batchId': batchId,
      'feeType': feeType,
      if (coursePaymentMode != null) 'coursePaymentMode': coursePaymentMode,
      'installments': installments.map((i) => i.toJson()).toList(),
    });
    return FeeStructure.fromJson(data);
  }

  @override
  Future<List<FeeStructure>> listFeeStructures({String? status, String? batchId}) async {
    final data = await _get('/fees/structures', queryParameters: {
      if (status != null) 'status': status,
      if (batchId != null) 'batchId': batchId,
    });
    final items = data['items'] as List;
    return items.map((e) => FeeStructure.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<FeeStructure> getFeeStructure(String id) async {
    final data = await _get('/fees/structures/$id');
    return FeeStructure.fromJson(data);
  }

  @override
  Future<FeeStructure> updateFeeStructure(String id, Map<String, dynamic> data) async {
    final result = await _send('PATCH', '/fees/structures/$id', data);
    return FeeStructure.fromJson(result);
  }

  @override
  Future<StudentFee> assignFee({
    required String studentId,
    required String feeStructureId,
    double? discountAmount,
    double? discountPercentage,
  }) async {
    final data = await _send('POST', '/fees/student', {
      'studentId': studentId,
      'feeStructureId': feeStructureId,
      if (discountAmount != null) 'discountAmount': discountAmount.toStringAsFixed(2),
      if (discountPercentage != null) 'discountPercentage': discountPercentage,
    });
    return StudentFee.fromJson(data);
  }

  @override
  Future<PaginatedResult<StudentFee>> listStudentFees({
    String? studentId,
    String? status,
    int page = 1,
  }) async {
    final data = await _get('/fees', queryParameters: {
      if (studentId != null) 'studentId': studentId,
      if (status != null) 'status': status,
      'page': page,
    });
    return PaginatedResult.fromJson(data, StudentFee.fromJson);
  }

  @override
  Future<StudentFee> getStudentFee(String id) async {
    final data = await _get('/fees/$id');
    return StudentFee.fromJson(data);
  }

  @override
  Future<StudentFeesResult> getFeesForStudent(String studentId) async {
    final data = await _get('/fees/student/$studentId');
    return StudentFeesResult.fromJson(data);
  }

  @override
  Future<FeeDashboardSummary> getDashboard() async {
    final data = await _get('/fees/dashboard');
    return FeeDashboardSummary.fromJson(data);
  }

  @override
  Future<Payment> recordPayment({
    required String studentId,
    required String studentFeeId,
    required String installmentId,
    required double amount,
    required String paymentMethod,
    String? transactionReference,
    DateTime? paymentDate,
    String? notes,
  }) async {
    final data = await _send('POST', '/payments', {
      'studentId': studentId,
      'studentFeeId': studentFeeId,
      'installmentId': installmentId,
      'amount': amount.toStringAsFixed(2),
      'paymentMethod': paymentMethod,
      if (transactionReference != null && transactionReference.isNotEmpty)
        'transactionReference': transactionReference,
      if (paymentDate != null) 'paymentDate': paymentDate.toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Payment.fromJson(data);
  }

  @override
  Future<PaginatedResult<Payment>> listPayments({
    String? studentId,
    String? studentFeeId,
    int page = 1,
  }) async {
    final data = await _get('/payments', queryParameters: {
      if (studentId != null) 'studentId': studentId,
      if (studentFeeId != null) 'studentFeeId': studentFeeId,
      'page': page,
    });
    return PaginatedResult.fromJson(data, Payment.fromJson);
  }

  @override
  Future<Payment> getPayment(String id) async {
    final data = await _get('/payments/$id');
    return Payment.fromJson(data);
  }

  @override
  Future<Receipt> getReceipt(String id) async {
    final data = await _get('/receipts/$id');
    return Receipt.fromJson(data);
  }

  Future<Map<String, dynamic>> _get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  Future<Map<String, dynamic>> _send(String method, String path, Map<String, dynamic>? body) async {
    try {
      final response = await _dio.request(path, data: body, options: Options(method: method));
      return (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  AppException _toAppException(DioException e) {
    final message = e.response?.data is Map
        ? (e.response?.data['message'] as String? ?? 'Request failed')
        : 'Request failed';
    return AppException(message, statusCode: e.response?.statusCode);
  }
}
