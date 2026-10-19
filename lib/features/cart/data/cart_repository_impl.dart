import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/preferences_store.dart';
import '../domain/cart_item.dart';
import '../domain/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this._preferences, this._client);

  final PreferencesStore _preferences;
  final ApiClient _client;

  @override
  Future<void> clear() =>
      _preferences.writeJsonList(PreferencesStore.cartKey, []);

  @override
  Future<List<CartItem>> load() async => _preferences
      .readJsonList(PreferencesStore.cartKey)
      .map(CartItem.fromJson)
      .where((item) => item.product.id > 0 && item.quantity > 0)
      .toList();

  @override
  Future<void> save(List<CartItem> items) => _preferences.writeJsonList(
    PreferencesStore.cartKey,
    items.map((item) => item.toJson()).toList(),
  );

  @override
  Future<Result<void>> checkout({
    required int userId,
    required List<CartItem> items,
  }) async {
    try {
      await _client.dio.post<void>(
        '/carts/add',
        data: {
          'userId': userId,
          'products': [
            for (final item in items)
              {'id': item.product.id, 'quantity': item.quantity},
          ],
        },
      );
      return const Success(null);
    } catch (error) {
      return Error(_client.mapError(error));
    }
  }
}
