import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/result.dart';
import 'package:shopsphere/features/auth/domain/app_user.dart';
import 'package:shopsphere/features/auth/domain/auth_repository.dart';
import 'package:shopsphere/features/auth/domain/login_use_case.dart';

void main() {
  test(
    'login use case delegates credentials and returns the session',
    () async {
      final repository = _MockAuthRepository();
      const session = AuthSession(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        user: AppUser(
          id: 12,
          firstName: 'Alex',
          lastName: 'Morgan',
          email: 'alex@example.com',
          phone: '555-0100',
          image: '',
        ),
      );
      when(
        () => repository.login(username: 'emilys', password: 'emilyspass'),
      ).thenAnswer((_) async => const Success(session));

      final result = await LoginUseCase(repository)(
        username: 'emilys',
        password: 'emilyspass',
      );

      expect(result, const Success<AuthSession>(session));
      verify(
        () => repository.login(username: 'emilys', password: 'emilyspass'),
      ).called(1);
    },
  );
}

class _MockAuthRepository extends Mock implements AuthRepository {}
