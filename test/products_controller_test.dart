import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/di/providers.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/core/error/result.dart';
import 'package:shopsphere/features/products/domain/product.dart';
import 'package:shopsphere/features/products/domain/product_category.dart';
import 'package:shopsphere/features/products/domain/products_repository.dart';
import 'package:shopsphere/features/products/presentation/products_controller.dart';

void main() {
  const product = Product(
    id: 1,
    title: 'Phone',
    description: '',
    price: 100,
    discountPercentage: 10,
    rating: 4,
    stock: 2,
    thumbnail: '',
    images: [],
    category: 'smartphones',
  );

  test('controller loads product data into a success state', () async {
    final repository = _FakeProductsRepository(
      pageResult: const Success(ProductsPage(products: [product], total: 1)),
    );
    final container = ProviderContainer(
      overrides: [productsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container.read(productsProvider);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(productsProvider);
    expect(state.isInitialLoading, isFalse);
    expect(state.products, [product]);
  });

  test('controller exposes a failure state when loading fails', () async {
    final repository = _FakeProductsRepository(
      pageResult: Error(Failure.server('Catalogue unavailable')),
    );
    final container = ProviderContainer(
      overrides: [productsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container.read(productsProvider);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(productsProvider);
    expect(state.isInitialLoading, isFalse);
    expect(state.failure, isA<ServerFailure>());
  });

  test('controller emits loading then successful product states', () async {
    final repository = _FakeProductsRepository(
      pageResult: const Success(ProductsPage(products: [product], total: 1)),
    );
    final container = ProviderContainer(
      overrides: [productsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final states = <ProductsState>[];
    container.listen<ProductsState>(
      productsProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );

    await Future<void>.delayed(Duration.zero);

    expect(states.map((state) => state.isInitialLoading), [true, true, false]);
    expect(states.last.products, [product]);
  });

  test('controller passes selected sorting to the repository', () async {
    final repository = _FakeProductsRepository(
      pageResult: const Success(ProductsPage(products: [product], total: 1)),
    );
    final container = ProviderContainer(
      overrides: [productsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container.read(productsProvider);
    await Future<void>.delayed(Duration.zero);
    await container
        .read(productsProvider.notifier)
        .selectSort(ProductSort.rating);

    expect(repository.sorts.last, ProductSort.rating);
    expect(container.read(productsProvider).sort, ProductSort.rating);
  });

  test('a stale refresh cannot overwrite newer filter results', () async {
    final repository = _DeferredProductsRepository();
    final container = ProviderContainer(
      overrides: [productsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container.read(productsProvider);
    await Future<void>.delayed(Duration.zero);
    final refresh = container
        .read(productsProvider.notifier)
        .selectSort(ProductSort.rating);
    await Future<void>.delayed(Duration.zero);

    repository.requests[1].complete(
      const Success(ProductsPage(products: [product], total: 1)),
    );
    await refresh;
    repository.requests[0].complete(
      const Success(ProductsPage(products: [], total: 0)),
    );
    await Future<void>.delayed(Duration.zero);

    expect(container.read(productsProvider).products, [product]);
    expect(container.read(productsProvider).sort, ProductSort.rating);
  });
}

class _DeferredProductsRepository implements ProductsRepository {
  final requests = <Completer<Result<ProductsPage>>>[];

  @override
  Future<Result<List<ProductCategory>>> getCategories() async =>
      const Success([]);

  @override
  Future<Result<Product>> getProduct(int id) async =>
      const Error(NotFoundFailure('Not found'));

  @override
  Future<Result<ProductsPage>> getProducts({
    required int skip,
    required int limit,
    String query = '',
    String? category,
    ProductSort sort = ProductSort.featured,
  }) {
    final request = Completer<Result<ProductsPage>>();
    requests.add(request);
    return request.future;
  }
}

class _FakeProductsRepository implements ProductsRepository {
  _FakeProductsRepository({required this.pageResult});

  final Result<ProductsPage> pageResult;
  final List<ProductSort> sorts = [];

  @override
  Future<Result<List<ProductCategory>>> getCategories() async =>
      const Success([]);

  @override
  Future<Result<Product>> getProduct(int id) async =>
      const Error(NotFoundFailure('Not found'));

  @override
  Future<Result<ProductsPage>> getProducts({
    required int skip,
    required int limit,
    String query = '',
    String? category,
    ProductSort sort = ProductSort.featured,
  }) async {
    sorts.add(sort);
    return pageResult;
  }
}
