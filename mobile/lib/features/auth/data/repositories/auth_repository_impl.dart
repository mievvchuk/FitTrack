import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_api_data_source.dart';
import '../datasources/firebase_auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required FirebaseAuthRemoteDataSource firebaseDataSource,
    required AuthApiDataSource apiDataSource,
  })  : _firebaseDataSource = firebaseDataSource,
        _apiDataSource = apiDataSource;

  final FirebaseAuthRemoteDataSource _firebaseDataSource;
  final AuthApiDataSource _apiDataSource;

  @override
  AuthUser? get currentUser => _firebaseDataSource.currentUser;

  @override
  Stream<AuthUser?> get authStateChanges {
    return _firebaseDataSource.authStateChanges;
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await _firebaseDataSource.signInWithEmail(
      email: email,
      password: password,
    );
    return _apiDataSource.syncUser(user);
  }

  @override
  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await _firebaseDataSource.registerWithEmail(
      email: email,
      password: password,
    );
    return _apiDataSource.syncUser(user);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final user = await _firebaseDataSource.signInWithGoogle();
    return _apiDataSource.syncUser(user);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseDataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<void> signOut() {
    return _firebaseDataSource.signOut();
  }
}
