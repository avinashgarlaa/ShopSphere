import 'package:flutter/material.dart';

import '../utils/layout.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: compact ? 40 : 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}

class ProductShimmer extends StatelessWidget {
  const ProductShimmer({super.key, this.count = 8});
  final int count;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: LayoutBreakpoints.gridColumns(
          MediaQuery.sizeOf(context).width,
        ),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: constraints.maxWidth >= LayoutBreakpoints.expanded
            ? .72
            : .62,
      ),
      itemCount: count,
      itemBuilder: (context, _) => _SkeletonCard(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    ),
  );
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 72,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    ),
  );
}
