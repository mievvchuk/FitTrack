import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  const SecureStorageService(this._storage);

  static const accessTokenKey = 'fittrack.access_token';
  static const refreshTokenKey = 'fittrack.refresh_token';

  final FlutterSecureStorage _storage;

  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }

  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await write(accessTokenKey, accessToken);
    await write(refreshTokenKey, refreshToken);
  }

  Future<String?> readAccessToken() {
    return read(accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return read(refreshTokenKey);
  }

  Future<void> clearAuthTokens() async {
    await delete(accessTokenKey);
    await delete(refreshTokenKey);
  }
}
