import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsphere/core/di/providers.dart';

import '../../../core/error/result.dart';
import '../../../core/storage/session_store.dart';
import '../domain/app_user.dart';
import '../domain/login_use_case.dart';

sealed class SessionState {
  const SessionState();
}

class SessionChecking extends SessionState {
  const SessionChecking();
}

class SessionRestoreFailed extends SessionState {
  const SessionRestoreFailed();
}

class SessionSignedOut extends SessionState {
  const SessionSignedOut([this.notice]);
  final String? notice;
}

class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.user);
  final AppUser? user;
}

class SessionController extends Notifier<SessionState> {
  SessionStore get _store => ref.read(sessionStoreProvider);
  LoginUseCase get _login => ref.read(loginUseCaseProvider);

  @override
  SessionState build() {
    Future<void>.microtask(restore);
    return const SessionChecking();
  }

  Future<void> restore() async {
    state = const SessionChecking();
    try {
      state = await _store.hasSession
          ? const SessionSignedIn(null)
          : const SessionSignedOut();
    } catch (error, stackTrace) {
      debugPrint('Unable to restore session: $error\n$stackTrace');
      state = const SessionRestoreFailed();
    }
  }

  Future<Result<AuthSession>> login(String username, String password) async {
    final result = await _login(username: username, password: password);
    if (result is Success<AuthSession>) {
      state = SessionSignedIn(result.data.user);
    }
    return result;
  }

  Future<void> signOut({String? notice}) async {
    await _store.clear();
    state = SessionSignedOut(notice);
  }
}
