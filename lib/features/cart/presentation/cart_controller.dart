import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsphere/core/di/providers.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/storage/session_store.dart';
import '../../products/domain/product.dart';
import '../domain/cart_item.dart';
import '../domain/cart_repository.dart';

class CartState {
  const CartState({
    this.items = const [],
    this.isReady = false,
    this.isCheckingOut = false,
  });

  final List<CartItem> items;
  final bool isReady;
  final bool isCheckingOut;

  CartTotals get totals => CartTotals.fromItems(items);

  CartState copyWith({
    List<CartItem>? items,
    bool? isReady,
    bool? isCheckingOut,
  }) => CartState(
    items: items ?? this.items,
    isReady: isReady ?? this.isReady,
    isCheckingOut: isCheckingOut ?? this.isCheckingOut,
  );
}

class CartController extends Notifier<CartState> {
  CartRepository get _repository => ref.read(cartRepositoryProvider);
  SessionStore get _sessionStore => ref.read(sessionStoreProvider);

  @override
  CartState build() {
    Future<void>.microtask(_restore);
    return const CartState();
  }

  Future<void> _restore() async {
    final items = await _repository.load();
    state = state.copyWith(items: items, isReady: true);
  }

  Future<void> add(Product product, int quantity) async {
    final index = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );
    final items = [...state.items];
    if (index == -1) {
      items.add(CartItem(product: product, quantity: quantity));
    } else {
      final item = items[index];
      items[index] = item.copyWith(
        quantity: (item.quantity + quantity).clamp(1, product.stock),
      );
    }
    await _setItems(items);
  }

  Future<void> setQuantity(int productId, int quantity) async {
    final items = [
      for (final item in state.items)
        if (item.product.id != productId)
          item
        else if (quantity > 0)
          item.copyWith(quantity: quantity.clamp(1, item.product.stock)),
    ];
    await _setItems(items);
  }

  Future<void> remove(int productId) => _setItems(
    state.items.where((item) => item.product.id != productId).toList(),
  );

  Future<void> _setItems(List<CartItem> items) async {
    state = state.copyWith(items: items);
    await _repository.save(items);
  }

  Future<Result<void>> checkout() async {
    final userId = await _sessionStore.userId;
    if (userId == null) {
      return Error(Failure.unauthorized());
    }
    state = state.copyWith(isCheckingOut: true);
    final result = await _repository.checkout(
      userId: userId,
      items: state.items,
    );
    if (result is Success<void>) await _setItems([]);
    state = state.copyWith(isCheckingOut: false);
    return result;
  }
}
