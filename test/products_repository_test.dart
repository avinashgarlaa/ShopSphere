import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/core/error/result.dart';
import 'package:shopsphere/core/network/api_client.dart';
import 'package:shopsphere/core/storage/session_store.dart';
import 'package:shopsphere/features/products/data/products_repository_impl.dart';
import 'package:shopsphere/features/products/domain/product.dart';

void main() {
  ProductsRepositoryImpl repositoryFor(Interceptor interceptor) {
    final dio = Dio()..interceptors.add(interceptor);
    final client = ApiClient(
      const SessionStore(FlutterSecureStorage()),
      client: dio,
    );
    return ProductsRepositoryImpl(client);
  }

  test(
    'repository returns a typed product page on a successful response',
    () async {
      final repository = repositoryFor(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'total': 1,
                'products': [
                  {
                    'id': 1,
                    'title': 'Phone',
                    'price': 99,
                    'discountPercentage': 10,
                    'rating': 4.2,
                    'stock': 5,
                    'thumbnail': 'https://example.com/phone.jpg',
                  },
                ],
              },
            ),
          ),
        ),
      );

      final result = await repository.getProducts(skip: 0, limit: 20);

      expect(result, isA<Success<ProductsPage>>());
      final page = (result as Success<ProductsPage>).data;
      expect(page.total, 1);
      expect(page.products.single.title, 'Phone');
    },
  );

  test('repository maps an HTTP 500 response to a server failure', () async {
    final repository = repositoryFor(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 500),
          ),
        ),
      ),
    );

    final result = await repository.getProducts(skip: 0, limit: 20);

    expect(result, isA<Error<ProductsPage>>());
    expect((result as Error<ProductsPage>).error, isA<ServerFailure>());
  });

  test('repository maps a connection error to a network failure', () async {
    final repository = repositoryFor(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ),
      ),
    );

    final result = await repository.getProducts(skip: 0, limit: 20);

    expect(result, isA<Error<ProductsPage>>());
    expect((result as Error<ProductsPage>).error, isA<NetworkFailure>());
  });

  test(
    'repository maps a missing product response to a not-found failure',
    () async {
      final repository = repositoryFor(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(requestOptions: options, statusCode: 404),
            ),
          ),
        ),
      );

      final result = await repository.getProduct(9999);

      expect(result, isA<Error<Product>>());
      expect((result as Error<Product>).error, isA<NotFoundFailure>());
    },
  );
}
