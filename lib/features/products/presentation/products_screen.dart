import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/result.dart';
import '../../../core/localization/shop_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/layout.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/product.dart';
import '../domain/product_category.dart';
import '../domain/products_repository.dart';
import 'product_detail_screen.dart';
import 'products_controller.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key, this.expanded = false});

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedProductProvider);
    if (!expanded) return const _ProductsPane();
    return Row(
      children: [
        const Expanded(flex: 3, child: _ProductsPane(expanded: true)),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: selected == null
              ? const _SelectProductHint()
              : ProductDetailScreen(
                  key: ValueKey(selected.id),
                  productId: selected.id,
                  embedded: true,
                ),
        ),
      ],
    );
  }
}

class _ProductsPane extends ConsumerWidget {
  const _ProductsPane({this.expanded = false});

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ShopLocalizations.of(context);
    final state = ref.watch(productsProvider);
    final controller = ref.read(productsProvider.notifier);
    final wishlistOnly = ref.watch(showWishlistOnlyProvider);
    final isOffline = state.isOffline;
    return Column(
      children: [
        if (!expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.text('findFavorite'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        strings.text('thoughtfulFinds'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.local_mall_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        if (isOffline)
          MaterialBanner(
            content: Text(strings.text('offlineBanner')),
            leading: const Icon(Icons.cloud_off_outlined),
            actions: [
              TextButton(
                onPressed: controller.refresh,
                child: Text(strings.text('retry')),
              ),
            ],
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, expanded ? 8 : 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: controller.search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: strings.text('searchProducts'),
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: wishlistOnly
                    ? strings.text('showProducts')
                    : strings.text('showWishlist'),
                isSelected: wishlistOnly,
                onPressed: () =>
                    ref.read(showWishlistOnlyProvider.notifier).state =
                        !wishlistOnly,
                icon: Icon(
                  wishlistOnly ? Icons.favorite : Icons.favorite_border,
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<ProductSort>(
                tooltip: strings.text('sortProducts'),
                onSelected: controller.selectSort,
                itemBuilder: (_) => [
                  for (final sort in ProductSort.values)
                    CheckedPopupMenuItem(
                      value: sort,
                      checked: state.sort == sort,
                      child: Text(
                        strings.text(switch (sort) {
                          ProductSort.featured => 'featured',
                          ProductSort.priceAscending => 'priceLowHigh',
                          ProductSort.priceDescending => 'priceHighLow',
                          ProductSort.rating => 'topRated',
                          ProductSort.title => 'titleAZ',
                        }),
                      ),
                    ),
                ],
                icon: const Icon(Icons.tune_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  minimumSize: const Size(52, 52),
                ),
              ),
            ],
          ),
        ),
        _CategoryStrip(
          selected: state.category,
          onSelected: controller.selectCategory,
        ),
        Expanded(
          child: _ProductResults(
            state: state,
            controller: controller,
            expanded: expanded,
            wishlistOnly: wishlistOnly,
          ),
        ),
      ],
    );
  }
}

class _CategoryStrip extends ConsumerWidget {
  const _CategoryStrip({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return SizedBox(
      height: 52,
      child: categories.when(
        loading: () => const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, _) =>
            _CategoryRetry(onRetry: () => ref.invalidate(categoriesProvider)),
        data: (result) => switch (result) {
          Success<List<ProductCategory>>(:final data) => ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(ShopLocalizations.of(context).text('all')),
                  selected: selected == null,
                  onSelected: (_) => onSelected(null),
                ),
              ),
              for (final category in data)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: selected == category.slug,
                    onSelected: (_) => onSelected(category.slug),
                  ),
                ),
            ],
          ),
          Error<List<ProductCategory>>() => _CategoryRetry(
            onRetry: () => ref.invalidate(categoriesProvider),
          ),
        },
      ),
    );
  }
}

class _CategoryRetry extends StatelessWidget {
  const _CategoryRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: Text(ShopLocalizations.of(context).text('categoriesRetry')),
    ),
  );
}

class _ProductResults extends ConsumerWidget {
  const _ProductResults({
    required this.state,
    required this.controller,
    required this.expanded,
    required this.wishlistOnly,
  });

  final ProductsState state;
  final ProductsController controller;
  final bool expanded;
  final bool wishlistOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ShopLocalizations.of(context);
    final wishlist = ref.watch(wishlistProvider);
    final products = wishlistOnly ? wishlist.values.toList() : state.products;
    if (!wishlistOnly && state.isInitialLoading) return const ProductShimmer();
    if (!wishlistOnly && state.failure != null && state.products.isEmpty) {
      return ErrorView(
        message: state.failure!.message,
        onRetry: controller.refresh,
      );
    }
    if (products.isEmpty) {
      return EmptyView(
        title: wishlistOnly
            ? strings.text('wishlistEmpty')
            : strings.text('noProducts'),
        message: wishlistOnly
            ? strings.text('wishlistHint')
            : strings.text('noProductsHint'),
        action: OutlinedButton(
          onPressed: wishlistOnly
              ? () => ref.read(showWishlistOnlyProvider.notifier).state = false
              : controller.refresh,
          child: Text(
            wishlistOnly
                ? strings.text('browseProducts')
                : strings.text('tryAgain'),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: controller.refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (!wishlistOnly &&
                notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 320) {
              controller.loadMore();
            }
            return false;
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: LayoutBreakpoints.gridColumns(
                MediaQuery.sizeOf(context).width,
              ),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: expanded ? .7 : .62,
            ),
            itemCount:
                products.length +
                (!wishlistOnly &&
                        (state.isLoadingMore ||
                            (state.failure != null &&
                                state.products.isNotEmpty))
                    ? 1
                    : 0),
            itemBuilder: (context, index) {
              if (index == products.length) {
                if (state.isLoadingMore) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Center(
                  child: TextButton.icon(
                    onPressed: controller.loadMore,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(strings.text('loadMoreRetry')),
                  ),
                );
              }
              final product = products[index];
              return _ProductCard(
                product: product,
                onTap: () {
                  if (expanded) {
                    ref.read(selectedProductProvider.notifier).state = product;
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ProductDetailScreen(productId: product.id),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isSaved = ref.watch(wishlistProvider).containsKey(product.id);
    return Semantics(
      button: true,
      label: '${product.title}, ${formatCurrency(product.salePrice)}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'product-${product.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: product.thumbnail,
                            fit: BoxFit.contain,
                            placeholder: (_, _) => ColoredBox(
                              color: scheme.surfaceContainerHighest,
                            ),
                            errorWidget: (_, _, _) => ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            ShopLocalizations.of(context)
                                .text('discountBadge')
                                .replaceAll(
                                  '{amount}',
                                  product.discountPercentage.toStringAsFixed(0),
                                ),
                            style: TextStyle(
                              color: scheme.onTertiaryContainer,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: IconButton.filledTonal(
                          tooltip: isSaved
                              ? ShopLocalizations.of(
                                  context,
                                ).text('removeWishlist')
                              : ShopLocalizations.of(
                                  context,
                                ).text('saveWishlist'),
                          onPressed: () => ref
                              .read(wishlistProvider.notifier)
                              .toggle(product),
                          icon: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? scheme.error : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        formatCurrency(product.salePrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (product.discountPercentage > 0) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          formatCurrency(product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                decoration: TextDecoration.lineThrough,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xffd89222),
                      size: 17,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const Spacer(),
                    if (!product.isInStock)
                      Text(
                        ShopLocalizations.of(context).text('soldOut'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectProductHint extends StatelessWidget {
  const _SelectProductHint();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 54,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            ShopLocalizations.of(context).text('selectProduct'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            ShopLocalizations.of(context).text('detailHint'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
