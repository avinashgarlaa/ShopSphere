import '../../../core/error/result.dart';
import 'app_user.dart';

abstract interface class AuthRepository {
  Future<Result<AuthSession>> login({
    required String username,
    required String password,
  });

  Future<Result<AppUser>> getCurrentUser();
  Future<void> logout();
}
