import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsphere/core/di/providers.dart';

import '../../../core/error/result.dart';
import '../../../core/localization/shop_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/cart_item.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ShopLocalizations.of(context);
    final cart = ref.watch(cartProvider);
    if (!cart.isReady) return const Center(child: CircularProgressIndicator());
    if (cart.items.isEmpty) {
      return EmptyView(
        title: strings.text('emptyCart'),
        message: strings.text('emptyCartHint'),
        action: FilledButton.icon(
          onPressed: () => ref.read(navigationIndexProvider.notifier).state = 0,
          icon: const Icon(Icons.storefront_outlined),
          label: Text(strings.text('exploreProducts')),
        ),
      );
    }
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final items = _CartItems(items: cart.items);
    final summary = _CheckoutSummary(cart: cart);
    return wide
        ? Row(
            children: [
              Expanded(child: items),
              SizedBox(
                width: 370,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: summary,
                ),
              ),
            ],
          )
        : Column(
            children: [
              Expanded(child: items),
              Padding(padding: const EdgeInsets.all(16), child: summary),
            ],
          );
  }
}

class _CartItems extends ConsumerWidget {
  const _CartItems({required this.items});
  final List<CartItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: items.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
      final strings = ShopLocalizations.of(context);
      final item = items[index];
      return Dismissible(
        key: ValueKey(item.product.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
        onDismissed: (_) =>
            ref.read(cartProvider.notifier).remove(item.product.id),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: item.product.thumbnail,
                    width: 86,
                    height: 86,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const SizedBox(
                      width: 86,
                      height: 86,
                      child: Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatCurrency(item.product.salePrice),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            tooltip: strings.text('decreaseQuantity'),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .setQuantity(
                                  item.product.id,
                                  item.quantity - 1,
                                ),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '${item.quantity}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            tooltip: strings.text('increaseQuantity'),
                            onPressed: item.quantity < item.product.stock
                                ? () => ref
                                      .read(cartProvider.notifier)
                                      .setQuantity(
                                        item.product.id,
                                        item.quantity + 1,
                                      )
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip:
                      '${strings.text('removeItem')} ${item.product.title}',
                  onPressed: () =>
                      ref.read(cartProvider.notifier).remove(item.product.id),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _CheckoutSummary extends ConsumerWidget {
  const _CheckoutSummary({required this.cart});
  final CartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ShopLocalizations.of(context);
    final totals = cart.totals;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.text('orderSummary'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _PriceRow(
              label:
                  '${strings.text('subtotal')} (${totals.itemCount} ${strings.text('items')})',
              value: totals.subtotal,
            ),
            const SizedBox(height: 10),
            _PriceRow(
              label: strings.text('discounts'),
              value: -totals.discount,
              emphasized: true,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            _PriceRow(
              label: strings.text('grandTotal'),
              value: totals.total,
              total: true,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: cart.isCheckingOut
                  ? null
                  : () => _checkout(context, ref),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              icon: cart.isCheckingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline),
              label: Text(
                cart.isCheckingOut
                    ? strings.text('placingOrder')
                    : strings.text('placeOrder'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(cartProvider.notifier).checkout();
    if (!context.mounted) return;
    if (result is Success<void>) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const OrderSuccessScreen()),
      );
    } else if (result is Error<void>) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error.message)));
    }
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.total = false,
    this.emphasized = false,
  });
  final String label;
  final double value;
  final bool total;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: total ? Theme.of(context).textTheme.titleMedium : null,
        ),
      ),
      Text(
        formatCurrency(value),
        style:
            (total ? Theme.of(context).textTheme.titleMedium : null)?.copyWith(
              fontWeight: FontWeight.bold,
            ) ??
            TextStyle(
              color: emphasized ? Theme.of(context).colorScheme.tertiary : null,
            ),
      ),
    ],
  );
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(ShopLocalizations.of(context).text('orderConfirmed')),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 50,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              ShopLocalizations.of(context).text('orderPlaced'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              ShopLocalizations.of(context).text('orderThanks'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                ShopLocalizations.of(context).text('continueShopping'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
