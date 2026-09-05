import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/fee_repository_impl.dart';
import '../../domain/fee_models.dart';
import '../../domain/fee_repository.dart';

final feeRepositoryProvider = Provider<FeeRepository>((ref) => FeeRepositoryImpl());

final feeDashboardProvider = FutureProvider.autoDispose<FeeDashboardSummary>((ref) async {
  return ref.watch(feeRepositoryProvider).getDashboard();
});

final feeStructuresProvider =
    FutureProvider.autoDispose.family<List<FeeStructure>, String?>((ref, status) async {
  return ref.watch(feeRepositoryProvider).listFeeStructures(status: status);
});

final feeStructureDetailProvider =
    FutureProvider.family<FeeStructure, String>((ref, id) async {
  return ref.watch(feeRepositoryProvider).getFeeStructure(id);
});

final studentFeeDetailProvider = FutureProvider.family<StudentFee, String>((ref, id) async {
  return ref.watch(feeRepositoryProvider).getStudentFee(id);
});

final feesForStudentProvider =
    FutureProvider.family<StudentFeesResult, String>((ref, studentId) async {
  return ref.watch(feeRepositoryProvider).getFeesForStudent(studentId);
});
