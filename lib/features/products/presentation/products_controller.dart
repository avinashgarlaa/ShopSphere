import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsphere/core/di/providers.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/debouncer.dart';
import '../domain/product.dart';
import '../domain/products_repository.dart';

class ProductsState {
  const ProductsState({
    this.products = const [],
    this.total = 0,
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.failure,
    this.query = '',
    this.category,
    this.sort = ProductSort.featured,
    this.isOffline = false,
  });

  static const pageSize = 20;
  final List<Product> products;
  final int total;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final Failure? failure;
  final String query;
  final String? category;
  final ProductSort sort;
  final bool isOffline;

  bool get hasMore => products.length < total;
  bool get isEmpty => !isInitialLoading && failure == null && products.isEmpty;

  ProductsState copyWith({
    List<Product>? products,
    int? total,
    bool? isInitialLoading,
    bool? isLoadingMore,
    Failure? failure,
    bool clearFailure = false,
    String? query,
    String? category,
    bool clearCategory = false,
    ProductSort? sort,
    bool? isOffline,
  }) => ProductsState(
    products: products ?? this.products,
    total: total ?? this.total,
    isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    failure: clearFailure ? null : failure ?? this.failure,
    query: query ?? this.query,
    category: clearCategory ? null : category ?? this.category,
    sort: sort ?? this.sort,
    isOffline: isOffline ?? this.isOffline,
  );
}

class ProductsController extends Notifier<ProductsState> {
  final Debouncer _debouncer = Debouncer(const Duration(milliseconds: 400));
  var _requestGeneration = 0;
  ProductsRepository get _repository => ref.read(productsRepositoryProvider);

  @override
  ProductsState build() {
    ref.onDispose(_debouncer.dispose);
    Future<void>.microtask(refresh);
    return const ProductsState();
  }

  void search(String value) {
    state = state.copyWith(query: value);
    _debouncer(() => refresh());
  }

  Future<void> selectCategory(String? category) async {
    state = state.copyWith(category: category, clearCategory: category == null);
    await refresh();
  }

  Future<void> selectSort(ProductSort sort) async {
    if (state.sort == sort) return;
    state = state.copyWith(sort: sort);
    await refresh();
  }

  Future<void> refresh() async {
    final generation = ++_requestGeneration;
    final query = state.query;
    final category = state.category;
    final sort = state.sort;
    state = state.copyWith(
      products: [],
      total: 0,
      isInitialLoading: true,
      isLoadingMore: false,
      clearFailure: true,
      isOffline: false,
    );
    final result = await _repository.getProducts(
      skip: 0,
      limit: ProductsState.pageSize,
      query: query,
      category: category,
      sort: sort,
    );
    if (generation != _requestGeneration) return;
    if (result is Success<ProductsPage>) {
      state = state.copyWith(
        products: result.data.products,
        total: result.data.total,
        isInitialLoading: false,
        isOffline: result.data.isOfflineCache,
        clearFailure: true,
      );
    } else if (result is Error<ProductsPage>) {
      state = state.copyWith(isInitialLoading: false, failure: result.error);
    }
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) return;
    final generation = _requestGeneration;
    final products = state.products;
    final query = state.query;
    final category = state.category;
    final sort = state.sort;
    state = state.copyWith(isLoadingMore: true, clearFailure: true);
    final result = await _repository.getProducts(
      skip: products.length,
      limit: ProductsState.pageSize,
      query: query,
      category: category,
      sort: sort,
    );
    if (generation != _requestGeneration) return;
    if (result is Success<ProductsPage>) {
      state = state.copyWith(
        products: [...products, ...result.data.products],
        total: result.data.total,
        isLoadingMore: false,
        isOffline: result.data.isOfflineCache || state.isOffline,
      );
    } else if (result is Error<ProductsPage>) {
      state = state.copyWith(isLoadingMore: false, failure: result.error);
    }
  }
}
