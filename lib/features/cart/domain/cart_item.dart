import '../../products/domain/product.dart';

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get lineSubtotal => product.price * quantity;
  double get lineTotal => product.salePrice * quantity;
  double get lineDiscount => lineSubtotal - lineTotal;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: Product.fromJson(
      Map<String, dynamic>.from(json['product'] as Map? ?? const {}),
    ),
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };
}

class CartTotals {
  const CartTotals({
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.itemCount,
  });

  final double subtotal;
  final double discount;
  final double total;
  final int itemCount;

  factory CartTotals.fromItems(Iterable<CartItem> items) {
    var subtotal = 0.0;
    var discount = 0.0;
    var itemCount = 0;
    for (final item in items) {
      subtotal += item.lineSubtotal;
      discount += item.lineDiscount;
      itemCount += item.quantity;
    }
    return CartTotals(
      subtotal: subtotal,
      discount: discount,
      total: subtotal - discount,
      itemCount: itemCount,
    );
  }
}
