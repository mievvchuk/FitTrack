import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_user.dart';
import 'auth_dependencies.dart';
import 'auth_state.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final repository = ref.watch(authRepositoryProvider);
    final currentUser = repository.currentUser;
    final subscription = repository.authStateChanges.listen((user) {
      state = AuthState(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user,
      );
    });

    ref.onDispose(subscription.cancel);

    if (currentUser != null) {
      return AuthState(
        status: AuthStatus.authenticated,
        user: currentUser,
      );
    }

    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _runAuthAction(() {
      return ref.read(signInWithEmailProvider)(
            email: email,
            password: password,
          );
    });
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    await _runAuthAction(() {
      return ref.read(registerWithEmailProvider)(
            email: email,
            password: password,
          );
    });
  }

  Future<void> signInWithGoogle() async {
    await _runAuthAction(() {
      return ref.read(signInWithGoogleProvider)();
    });
  }

  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await ref.read(sendPasswordResetProvider)(email);
      state = state.copyWith(isLoading: false, clearError: true);
    } on AppException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
      );
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await ref.read(signOutProvider)();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
    );
  }

  Future<void> _runAuthAction(
    Future<AuthUser> Function() action,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await action();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } on AppException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
      );
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }
}
