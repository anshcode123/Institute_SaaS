import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/institutes_repository_impl.dart';
import '../../domain/institute.dart';
import '../../domain/institutes_repository.dart';

final institutesRepositoryProvider = Provider<InstitutesRepository>(
  (ref) => InstitutesRepositoryImpl(),
);

final institutesProvider =
    StateNotifierProvider<InstitutesNotifier, InstitutesState>((ref) {
  return InstitutesNotifier(ref.watch(institutesRepositoryProvider))..load();
});

class InstitutesState {
  const InstitutesState({
    this.institutes = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Institute> institutes;
  final bool isLoading;
  final String? errorMessage;

  InstitutesState copyWith({
    List<Institute>? institutes,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InstitutesState(
      institutes: institutes ?? this.institutes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class InstitutesNotifier extends StateNotifier<InstitutesState> {
  InstitutesNotifier(this._repository) : super(const InstitutesState());

  final InstitutesRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = InstitutesState(institutes: await _repository.getInstitutes());
    } catch (error) {
      state = InstitutesState(errorMessage: _message(error));
    }
  }

  Future<InstituteCreationResult?> create({
    required String name,
    required String email,
    required String adminName,
    String? phone,
    String? address,
  }) async {
    try {
      final result = await _repository.createInstitute(
        name: name,
        email: email,
        adminName: adminName,
        phone: phone,
        address: address,
      );
      state = state.copyWith(
        institutes: [result.institute, ...state.institutes],
        clearError: true,
      );
      return result;
    } catch (error) {
      state = state.copyWith(errorMessage: _message(error));
      rethrow;
    }
  }

  Future<void> updateStatus(Institute institute) async {
    try {
      final updated = await _repository.updateStatus(
        institute.id,
        institute.status == InstituteStatus.active
            ? InstituteStatus.suspended
            : InstituteStatus.active,
      );
      state = state.copyWith(
        institutes: state.institutes
            .map((item) => item.id == updated.id ? updated : item)
            .toList(),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: _message(error));
      rethrow;
    }
  }

  String _message(Object error) => error is AppException
      ? error.message
      : 'Unable to load institutes. Please try again.';
}
