import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsphere/core/error/result.dart';
import 'package:shopsphere/core/network/api_client.dart';
import 'package:shopsphere/core/storage/preferences_store.dart';
import 'package:shopsphere/core/storage/session_store.dart';
import 'package:shopsphere/features/products/data/products_repository_impl.dart';
import 'package:shopsphere/features/products/domain/product.dart';

void main() {
  test(
    'repository serves cached products when the network is unavailable',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      var online = true;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (!online) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.connectionError,
                  ),
                );
                return;
              }
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'total': 1,
                    'products': [
                      {
                        'id': 7,
                        'title': 'Cached phone',
                        'price': 99,
                        'discountPercentage': 0,
                        'rating': 4.2,
                        'stock': 5,
                        'thumbnail': '',
                      },
                    ],
                  },
                ),
              );
            },
          ),
        );
      final repository = ProductsRepositoryImpl(
        ApiClient(_SessionStoreStub(), client: dio),
        PreferencesStore(preferences),
      );

      final fresh = await repository.getProducts(skip: 0, limit: 20);
      expect(fresh, isA<Success<ProductsPage>>());

      online = false;
      final cached = await repository.getProducts(skip: 0, limit: 20);

      expect(cached, isA<Success<ProductsPage>>());
      final page = (cached as Success<ProductsPage>).data;
      expect(page.isOfflineCache, isTrue);
      expect(page.products.single.title, 'Cached phone');
    },
  );
}

class _SessionStoreStub implements SessionStore {
  @override
  Future<String?> get accessToken async => null;

  @override
  Future<bool> get hasSession async => false;

  @override
  Future<String?> get refreshToken async => null;

  @override
  Future<int?> get userId async => null;

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
