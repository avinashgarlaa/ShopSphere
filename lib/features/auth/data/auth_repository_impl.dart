import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/session_store.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._client, this._sessionStore);

  final ApiClient _client;
  final SessionStore _sessionStore;

  @override
  Future<Result<AuthSession>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password, 'expiresInMins': 30},
      );
      final json = Map<String, dynamic>.from(response.data ?? const {});
      final session = AuthSession(
        accessToken: json['accessToken']?.toString() ?? '',
        refreshToken: json['refreshToken']?.toString() ?? '',
        user: AppUser.fromJson(json),
      );
      if (session.accessToken.isEmpty || session.user.id == 0) {
        return Error(_client.mapError(StateError('Malformed login response')));
      }
      await _sessionStore.save(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        userId: session.user.id,
      );
      return Success(session);
    } catch (error) {
      return Error(_client.mapError(error));
    }
  }

  @override
  Future<Result<AppUser>> getCurrentUser() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>('/auth/me');
      return Success(
        AppUser.fromJson(Map<String, dynamic>.from(response.data ?? const {})),
      );
    } catch (error) {
      return Error(_client.mapError(error));
    }
  }

  @override
  Future<void> logout() => _sessionStore.clear();
}
