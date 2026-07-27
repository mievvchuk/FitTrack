import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';

import '../config/api_config.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance;
});

final localAuthenticationProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(ref.watch(secureStorageProvider));
});

final apiBaseUrlProvider = Provider<String>((ref) {
  return ApiConfig.baseUrl;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final baseUrl = ref.watch(apiBaseUrlProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);

  return ApiClient(
    baseUrl: baseUrl,
    requireHttps: ApiConfig.requireHttps,
    tokenReader: () async {
      final accessToken = await secureStorage.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        return accessToken;
      }

      return firebaseAuth.currentUser?.getIdToken();
    },
  );
});
