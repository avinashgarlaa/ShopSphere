import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/di/providers.dart';
import 'package:shopsphere/core/error/result.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/core/localization/shop_localizations.dart';
import 'package:shopsphere/core/storage/session_store.dart';
import 'package:shopsphere/features/auth/domain/app_user.dart';
import 'package:shopsphere/features/auth/domain/auth_repository.dart';
import 'package:shopsphere/features/auth/domain/login_use_case.dart';
import 'package:shopsphere/app.dart';

void main() {
  Widget buildLogin() => ProviderScope(
    overrides: [
      sessionStoreProvider.overrideWithValue(_FakeSessionStore()),
      loginUseCaseProvider.overrideWithValue(
        LoginUseCase(_FakeAuthRepository()),
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
      home: const LoginScreen(),
    ),
  );

  testWidgets('login shows inline required-field validation', (tester) async {
    await tester.pumpWidget(buildLogin());
    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(1), '');
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter your username.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('login password visibility can be toggled', (tester) async {
    await tester.pumpWidget(buildLogin());
    final passwordField = tester.widget<EditableText>(
      find.byType(EditableText).at(1),
    );
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(1)).obscureText,
      isFalse,
    );
  });
}

class _FakeSessionStore implements SessionStore {
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

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Result<AppUser>> getCurrentUser() async =>
      const Error(UnknownFailure('Unused in login validation tests.'));

  @override
  Future<Result<AuthSession>> login({
    required String username,
    required String password,
  }) async => const Error(UnknownFailure('Unused in login validation tests.'));

  @override
  Future<void> logout() async {}
}
