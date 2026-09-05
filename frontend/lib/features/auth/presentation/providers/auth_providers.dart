import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/auth_repository.dart';
import 'auth_state.dart';

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    onSessionExpired: () async => ref.read(authControllerProvider.notifier).forceLogout(),
  );
});

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.initial()) {
    _restore();
  }

  final AuthRepository _repository;

  Future<void> _restore() async {
    state = const AuthState.loading();
    final session = await _repository.restoreSession();
    state = session != null
        ? AuthState.authenticated(session.user)
        : const AuthState.unauthenticated();
  }

  Future<void> loginSuperAdmin({required String email, required String password}) async {
    state = const AuthState.loading();
    try {
      final session = await _repository.loginSuperAdmin(email: email, password: password);
      state = AuthState.authenticated(session.user);
    } catch (e) {
      state = AuthState.error(_messageOf(e));
    }
  }

  Future<void> loginInstitute({required String instituteCode, required String password}) async {
    state = const AuthState.loading();
    try {
      final session = await _repository.loginInstitute(
        instituteCode: instituteCode,
        password: password,
      );
      state = AuthState.authenticated(session.user);
    } catch (e) {
      state = AuthState.error(_messageOf(e));
    }
  }

  Future<void> loginTeacher({required String email, required String password}) async {
    state = const AuthState.loading();
    try {
      final session = await _repository.loginTeacher(email: email, password: password);
      state = AuthState.authenticated(session.user);
    } catch (e) {
      state = AuthState.error(_messageOf(e));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState.unauthenticated();
  }

  /// Called by the Dio interceptor when a refresh attempt fails - drops
  /// the app back to unauthenticated without another network round-trip.
  void forceLogout() {
    state = const AuthState.unauthenticated();
  }

  String _messageOf(Object e) {
    if (e is AppException) return e.message;
    return e.toString();
  }
}
