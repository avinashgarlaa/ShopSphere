import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/app.dart';
import 'package:shopsphere/core/di/providers.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/core/error/result.dart';
import 'package:shopsphere/core/localization/shop_localizations.dart';
import 'package:shopsphere/core/storage/session_store.dart';
import 'package:shopsphere/features/auth/domain/app_user.dart';
import 'package:shopsphere/features/auth/domain/auth_repository.dart';
import 'package:shopsphere/features/auth/domain/login_use_case.dart';

void main() {
  Widget buildApp([SessionStore? sessionStore]) => ProviderScope(
    overrides: [
      sessionStoreProvider.overrideWithValue(
        sessionStore ?? _SignedOutSessionStore(),
      ),
      loginUseCaseProvider.overrideWithValue(
        LoginUseCase(_UnusedAuthRepository()),
      ),
    ],
    child: MaterialApp(
      supportedLocales: ShopLocalizations.supportedLocales,
      localizationsDelegates: const [
        ShopLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const AppGate(),
    ),
  );

  testWidgets('splash stays visible while restoring the session', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Preparing your finds…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1799));
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('session restore errors are visible and can be retried', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(_FailOnceSessionStore()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump();

    expect(
      find.text('We could not check your saved sign-in. Please retry.'),
      findsOneWidget,
    );
    expect(find.byType(LoginScreen), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

class _SignedOutSessionStore implements SessionStore {
  @override
  Future<String?> get accessToken async => null;

  @override
  Future<String?> get refreshToken async => null;

  @override
  Future<int?> get userId async => null;

  @override
  Future<bool> get hasSession async => false;

  @override
  Future<void> clear() async {}

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required int userId,
  }) async {}

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
}

class _FailOnceSessionStore extends _SignedOutSessionStore {
  var _shouldFail = true;

  @override
  Future<bool> get hasSession async {
    if (_shouldFail) {
      _shouldFail = false;
      throw StateError('Secure storage read failed');
    }
    return false;
  }
}

class _UnusedAuthRepository implements AuthRepository {
  @override
  Future<Result<AppUser>> getCurrentUser() async =>
      const Error(UnknownFailure('Not used in this test.'));

  @override
  Future<Result<AuthSession>> login({
    required String username,
    required String password,
  }) async => const Error(UnknownFailure('Not used in this test.'));

  @override
  Future<void> logout() async {}
}
