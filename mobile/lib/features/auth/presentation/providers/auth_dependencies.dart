import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/auth_api_data_source.dart';
import '../../data/datasources/firebase_auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/register_with_email.dart';
import '../../domain/usecases/send_password_reset.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';

final firebaseAuthRemoteDataSourceProvider =
    Provider<FirebaseAuthRemoteDataSource>((ref) {
  return FirebaseAuthRemoteDataSource(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final authApiDataSourceProvider = Provider<AuthApiDataSource>((ref) {
  return AuthApiDataSource(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    firebaseDataSource: ref.watch(firebaseAuthRemoteDataSourceProvider),
    apiDataSource: ref.watch(authApiDataSourceProvider),
  );
});

final signInWithEmailProvider = Provider<SignInWithEmail>((ref) {
  return SignInWithEmail(ref.watch(authRepositoryProvider));
});

final registerWithEmailProvider = Provider<RegisterWithEmail>((ref) {
  return RegisterWithEmail(ref.watch(authRepositoryProvider));
});

final signInWithGoogleProvider = Provider<SignInWithGoogle>((ref) {
  return SignInWithGoogle(ref.watch(authRepositoryProvider));
});

final sendPasswordResetProvider = Provider<SendPasswordReset>((ref) {
  return SendPasswordReset(ref.watch(authRepositoryProvider));
});

final signOutProvider = Provider<SignOut>((ref) {
  return SignOut(ref.watch(authRepositoryProvider));
});
