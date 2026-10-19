import '../../../core/error/result.dart';
import 'cart_item.dart';

abstract interface class CartRepository {
  Future<List<CartItem>> load();
  Future<void> save(List<CartItem> items);
  Future<void> clear();
  Future<Result<void>> checkout({
    required int userId,
    required List<CartItem> items,
  });
}
