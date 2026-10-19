import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/preferences_store.dart';
import '../domain/product.dart';
import '../domain/product_category.dart';
import '../domain/products_repository.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  const ProductsRepositoryImpl(this._client, [this._preferences]);

  final ApiClient _client;
  final PreferencesStore? _preferences;

  @override
  Future<Result<List<ProductCategory>>> getCategories() async {
    try {
      final response = await _client.dio.get<List<dynamic>>(
        '/products/categories',
      );
      final categories = (response.data ?? const [])
          .whereType<Map>()
          .map(
            (item) => ProductCategory.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((category) => category.slug.isNotEmpty)
          .toList();
      return Success(categories);
    } catch (error) {
      return Error(_client.mapError(error));
    }
  }

  @override
  Future<Result<Product>> getProduct(int id) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/products/$id',
      );
      return Success(
        Product.fromJson(Map<String, dynamic>.from(response.data ?? const {})),
      );
    } catch (error) {
      return Error(_client.mapError(error));
    }
  }

  @override
  Future<Result<ProductsPage>> getProducts({
    required int skip,
    required int limit,
    String query = '',
    String? category,
    ProductSort sort = ProductSort.featured,
  }) async {
    final parameters = <String, dynamic>{
      'limit': limit,
      'skip': skip,
      ...sort.queryParameters,
    };
    final normalizedQuery = query.trim();
    final path = normalizedQuery.isNotEmpty
        ? '/products/search'
        : category != null && category.isNotEmpty
        ? '/products/category/$category'
        : '/products';
    if (normalizedQuery.isNotEmpty) parameters['q'] = normalizedQuery;
    final queryString = Uri(
      queryParameters: {
        for (final entry in parameters.entries) entry.key: '${entry.value}',
      },
    ).query;
    final cacheKey =
        'product_page_${Uri.encodeComponent('$path?$queryString')}';
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        path,
        queryParameters: parameters,
      );
      final page = ProductsPage.fromJson(
        Map<String, dynamic>.from(response.data ?? const {}),
      );
      await _preferences?.writeJsonList(cacheKey, [page.toCacheJson()]);
      await _preferences?.writeInt('${cacheKey}_total', page.total);
      return Success(page);
    } catch (error) {
      final cached = _preferences?.readJsonList(cacheKey) ?? const [];
      if (cached.isNotEmpty) {
        final page = ProductsPage.fromJson(cached.first);
        final total = _preferences?.readInt('${cacheKey}_total') ?? page.total;
        return Success(
          ProductsPage(
            products: page.products,
            total: total,
            isOfflineCache: true,
          ),
        );
      }
      return Error(_client.mapError(error));
    }
  }
}
