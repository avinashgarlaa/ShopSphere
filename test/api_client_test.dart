import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/network/api_client.dart';
import 'package:shopsphere/core/storage/session_store.dart';

void main() {
  test('attaches the stored bearer token to the profile request', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'));
    final client = ApiClient(_FakeSessionStore(), client: dio);
    String? authorization;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          authorization = options.headers['Authorization'] as String?;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const {},
            ),
          );
        },
      ),
    );

    await client.dio.get<Map<String, dynamic>>('/auth/me');

    expect(authorization, 'Bearer test-access-token');
  });
}

class _FakeSessionStore implements SessionStore {
  @override
  Future<String?> get accessToken async => 'test-access-token';

  @override
  Future<bool> get hasSession async => true;

  @override
  Future<String?> get refreshToken async => null;

  @override
  Future<int?> get userId async => 1;

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
