import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../error/failure.dart';
import '../storage/session_store.dart';

class ApiClient {
  ApiClient(
    this._sessionStore, {
    Dio? client,
    Future<void> Function()? onSessionExpired,
  }) : dio =
           client ??
           Dio(
             BaseOptions(
               baseUrl: 'https://dummyjson.com',
               connectTimeout: const Duration(seconds: 12),
               receiveTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 12),
               headers: {'Content-Type': 'application/json'},
             ),
           ) {
    _onSessionExpired = onSessionExpired;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_isAuthEndpoint(options.path)) {
            final token = await _sessionStore.accessToken;
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final status = error.response?.statusCode;
          if ((status == 401 || status == 403) &&
              request.extra['authRetry'] == true) {
            await _expireSession();
            handler.next(error);
            return;
          }
          if ((status == 401 || status == 403) &&
              !_isAuthEndpoint(request.path) &&
              request.extra['authRetry'] != true) {
            final accessToken = await _refreshAccessToken();
            if (accessToken != null) {
              request
                ..extra['authRetry'] = true
                ..headers['Authorization'] = 'Bearer $accessToken';
              try {
                handler.resolve(await dio.fetch<dynamic>(request));
                return;
              } catch (retryError) {
                handler.next(retryError is DioException ? retryError : error);
                return;
              }
            }
          }
          handler.next(error);
        },
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
        ),
      );
    }
  }

  final SessionStore _sessionStore;
  final Dio dio;
  Future<void> Function()? _onSessionExpired;
  Future<String?>? _refreshing;

  bool _isAuthEndpoint(String path) =>
      path.startsWith('/auth/login') || path.startsWith('/auth/refresh');

  Future<String?> _refreshAccessToken() {
    final pending = _refreshing;
    if (pending != null) return pending;
    final request = _performRefresh();
    _refreshing = request;
    return request.whenComplete(() {
      if (identical(_refreshing, request)) _refreshing = null;
    });
  }

  Future<String?> _performRefresh() async {
    try {
      final refreshToken = await _sessionStore.refreshToken;
      final userId = await _sessionStore.userId;
      if (refreshToken == null || refreshToken.isEmpty || userId == null) {
        await _expireSession();
        return null;
      }
      final response =
          await Dio(
            BaseOptions(
              baseUrl: dio.options.baseUrl,
              connectTimeout: dio.options.connectTimeout,
              receiveTimeout: dio.options.receiveTimeout,
              sendTimeout: dio.options.sendTimeout,
              headers: {'Content-Type': 'application/json'},
            ),
          ).post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refreshToken': refreshToken, 'expiresInMins': 30},
          );
      final data = response.data ?? const <String, dynamic>{};
      final accessToken = data['accessToken']?.toString() ?? '';
      final nextRefreshToken = data['refreshToken']?.toString() ?? '';
      if (accessToken.isEmpty || nextRefreshToken.isEmpty) {
        await _expireSession();
        return null;
      }
      await _sessionStore.saveTokens(
        accessToken: accessToken,
        refreshToken: nextRefreshToken,
      );
      return accessToken;
    } catch (_) {
      await _expireSession();
      return null;
    }
  }

  Future<void> _expireSession() async {
    await _sessionStore.clear();
    await _onSessionExpired?.call();
  }

  Failure mapError(Object error) {
    if (error is SocketException) return Failure.network();
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return Failure.timeout();
      }
      if (error.type == DioExceptionType.connectionError) {
        return Failure.network();
      }
      final status = error.response?.statusCode;
      final data = error.response?.data;
      final apiMessage = data is Map<String, dynamic>
          ? data['message']?.toString()
          : null;
      return switch (status) {
        400 => Failure.validation(
          apiMessage == 'Invalid credentials'
              ? 'Invalid username or password.'
              : apiMessage ?? 'Please check your details and try again.',
        ),
        401 || 403 => Failure.unauthorized(),
        404 => Failure.notFound(),
        final status? when status >= 500 => Failure.server(),
        _ => Failure.unknown(
          apiMessage ?? 'We could not complete that request.',
        ),
      };
    }
    return Failure.unknown();
  }
}
