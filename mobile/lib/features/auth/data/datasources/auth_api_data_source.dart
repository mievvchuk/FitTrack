import '../../../../core/network/api_client.dart';
import '../../domain/entities/auth_user.dart';

class AuthApiDataSource {
  const AuthApiDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthUser> syncUser(AuthUser user) async {
    final response = await _apiClient.post(
      '/auth/sync-user',
      data: <String, dynamic>{
        'email': user.email,
        'display_name': user.displayName,
        'photo_url': user.photoUrl,
      },
    );

    final data = response.data;
    if (data is! Map) {
      return user;
    }

    return user.copyWith(
      apiUserId: data['id']?.toString(),
      roles: _stringList(data['roles'], fallback: user.roles),
      permissions: _stringList(
        data['permissions'],
        fallback: user.permissions,
      ),
    );
  }

  List<String> _stringList(Object? value, {required List<String> fallback}) {
    if (value is! List) {
      return fallback;
    }

    return value.map((item) => item.toString()).toList(growable: false);
  }
}
