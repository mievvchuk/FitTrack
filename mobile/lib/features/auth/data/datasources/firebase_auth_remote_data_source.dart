import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_user.dart';

class FirebaseAuthRemoteDataSource {
  FirebaseAuthRemoteDataSource({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _isGoogleInitialized = false;

  AuthUser? get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _requireUser(credential.user);
    } on FirebaseAuthException catch (error) {
      throw AppException(
        _mapFirebaseError(error),
        code: error.code,
      );
    }
  }

  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _requireUser(credential.user);
    } on FirebaseAuthException catch (error) {
      throw AppException(
        _mapFirebaseError(error),
        code: error.code,
      );
    }
  }

  Future<AuthUser> signInWithGoogle() async {
    try {
      await _initializeGoogleSignIn();

      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      return _requireUser(userCredential.user);
    } on FirebaseAuthException catch (error) {
      throw AppException(
        _mapFirebaseError(error),
        code: error.code,
      );
    } on GoogleSignInException catch (error) {
      throw AppException(
        error.description ?? 'Google Sign-In не виконано',
        code: error.code.name,
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AppException(
        _mapFirebaseError(error),
        code: error.code,
      );
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();

    try {
      await _googleSignIn.disconnect();
    } on Object {
      // Disconnect can fail if Google auth was never used in this session.
    }
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_isGoogleInitialized) {
      return;
    }

    await _googleSignIn.initialize();
    _isGoogleInitialized = true;
  }

  AuthUser _requireUser(User? user) {
    final authUser = _mapFirebaseUser(user);
    if (authUser == null) {
      throw const AppException('Користувача не знайдено після авторизації');
    }
    return authUser;
  }

  AuthUser? _mapFirebaseUser(User? user) {
    if (user == null || user.email == null) {
      return null;
    }

    return AuthUser(
      id: user.uid,
      email: user.email!,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
    );
  }

  String _mapFirebaseError(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Некоректний email',
      'user-disabled' => 'Акаунт вимкнено',
      'user-not-found' => 'Користувача не знайдено',
      'wrong-password' => 'Невірний пароль',
      'email-already-in-use' => 'Email вже використовується',
      'weak-password' => 'Пароль занадто слабкий',
      'network-request-failed' => 'Немає підключення до мережі',
      _ => error.message ?? 'Помилка авторизації',
    };
  }
}
