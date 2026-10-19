import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/result.dart';
import '../../../core/localization/shop_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/product.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.embedded = false,
  });

  final int productId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(productDetailsProvider(productId));
    final content = details.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => ErrorView(
        message: ShopLocalizations.of(context).text('productLoadError'),
        onRetry: () => ref.invalidate(productDetailsProvider(productId)),
      ),
      data: (result) => switch (result) {
        Success<Product>(:final data) => ProductDetailBody(
          product: data,
          embedded: embedded,
        ),
        Error<Product>(:final error) => ErrorView(
          message: error.message,
          onRetry: () => ref.invalidate(productDetailsProvider(productId)),
        ),
      },
    );
    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(
        title: Text(ShopLocalizations.of(context).text('productDetails')),
      ),
      body: content,
    );
  }
}

class ProductDetailBody extends ConsumerStatefulWidget {
  const ProductDetailBody({
    super.key,
    required this.product,
    this.embedded = false,
  });

  final Product product;
  final bool embedded;

  @override
  ConsumerState<ProductDetailBody> createState() => _ProductDetailBodyState();
}

class _ProductDetailBodyState extends ConsumerState<ProductDetailBody> {
  var _imageIndex = 0;
  var _quantity = 1;

  void _addToCart() {
    ref.read(cartProvider.notifier).add(widget.product, _quantity);
    final strings = ShopLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.title} ${strings.text('addedToCart')}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final scheme = Theme.of(context).colorScheme;
    final strings = ShopLocalizations.of(context);
    final isSaved = ref.watch(wishlistProvider).containsKey(product.id);
    final images = product.images.isEmpty
        ? [product.thumbnail]
        : product.images;
    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.embedded ? 20 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1.08,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (index) =>
                            setState(() => _imageIndex = index),
                        itemBuilder: (context, index) {
                          final image = CachedNetworkImage(
                            imageUrl: images[index],
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (_, _, _) => const ColoredBox(
                              color: Color(0xffeeeef5),
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 40,
                                ),
                              ),
                            ),
                          );
                          return index == 0
                              ? Hero(tag: 'product-${product.id}', child: image)
                              : image;
                        },
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (
                                var index = 0;
                                index < images.length;
                                index++
                              )
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: index == _imageIndex ? 20 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: index == _imageIndex
                                        ? scheme.primary
                                        : scheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(product.category.replaceAll('-', ' '))),
                  if (product.isInStock)
                    Chip(
                      avatar: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        '${product.stock} ${strings.text('inStock')}',
                      ),
                    )
                  else
                    Chip(
                      avatar: const Icon(
                        Icons.remove_shopping_cart_outlined,
                        size: 18,
                      ),
                      label: Text(strings.text('outOfStock')),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: isSaved
                        ? strings.text('removeWishlist')
                        : strings.text('saveWishlist'),
                    onPressed: () =>
                        ref.read(wishlistProvider.notifier).toggle(product),
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved ? scheme.error : null,
                    ),
                  ),
                ],
              ),
              if (product.brand != null && product.brand!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  product.brand!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    formatCurrency(product.salePrice),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: scheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formatCurrency(product.price),
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${product.discountPercentage.toStringAsFixed(0)}% ${strings.text('discountOff')}',
                    style: TextStyle(color: scheme.tertiary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${product.rating.toStringAsFixed(1)} ${strings.text('rating')}',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                product.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              if (product.isInStock) ...[
                Row(
                  children: [
                    Text(
                      strings.text('quantity'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: strings.text('decreaseQuantity'),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Semantics(
                      label: strings
                          .text('quantityValue')
                          .replaceAll('{count}', '$_quantity'),
                      child: Text(
                        '$_quantity',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: strings.text('increaseQuantity'),
                      onPressed: _quantity < product.stock
                          ? () => setState(() => _quantity++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: product.isInStock ? _addToCart : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(
                  product.isInStock
                      ? strings.text('addToCart')
                      : strings.text('outOfStock'),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                strings.text('reviews'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (product.reviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(strings.text('noReviews')),
                )
              else
                ...product.reviews.map(
                  (review) => Card(
                    margin: const EdgeInsets.only(top: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(review.rating.toStringAsFixed(1)),
                              const Spacer(),
                              Text(review.reviewerName),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(review.comment),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
