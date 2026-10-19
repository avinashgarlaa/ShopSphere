import '../../../core/error/result.dart';
import 'product.dart';
import 'product_category.dart';

enum ProductSort { featured, priceAscending, priceDescending, rating, title }

extension ProductSortApi on ProductSort {
  String get label => switch (this) {
    ProductSort.featured => 'Featured',
    ProductSort.priceAscending => 'Price: low to high',
    ProductSort.priceDescending => 'Price: high to low',
    ProductSort.rating => 'Top rated',
    ProductSort.title => 'Title: A to Z',
  };

  Map<String, String> get queryParameters => switch (this) {
    ProductSort.featured => const {},
    ProductSort.priceAscending => const {'sortBy': 'price', 'order': 'asc'},
    ProductSort.priceDescending => const {'sortBy': 'price', 'order': 'desc'},
    ProductSort.rating => const {'sortBy': 'rating', 'order': 'desc'},
    ProductSort.title => const {'sortBy': 'title', 'order': 'asc'},
  };
}

abstract interface class ProductsRepository {
  Future<Result<ProductsPage>> getProducts({
    required int skip,
    required int limit,
    String query,
    String? category,
    ProductSort sort,
  });

  Future<Result<List<ProductCategory>>> getCategories();
  Future<Result<Product>> getProduct(int id);
}
