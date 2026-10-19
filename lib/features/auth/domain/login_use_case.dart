import '../../../core/error/result.dart';
import 'app_user.dart';
import 'auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession>> call({
    required String username,
    required String password,
  }) => _repository.login(username: username, password: password);
}
