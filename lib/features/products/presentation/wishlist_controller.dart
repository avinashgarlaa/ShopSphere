import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/product.dart';

class WishlistController extends Notifier<Map<int, Product>> {
  static const _storageKey = 'wishlist_products';

  @override
  Map<int, Product> build() {
    final saved = ref
        .read(preferencesStoreProvider)
        .readJsonList(_storageKey)
        .map(Product.fromJson)
        .where((product) => product.id > 0);
    return {for (final product in saved) product.id: product};
  }

  Future<void> toggle(Product product) async {
    final next = Map<int, Product>.of(state);
    if (next.remove(product.id) == null) next[product.id] = product;
    state = Map.unmodifiable(next);
    await ref
        .read(preferencesStoreProvider)
        .writeJsonList(
          _storageKey,
          state.values.map((product) => product.toJson()).toList(),
        );
  }
}
