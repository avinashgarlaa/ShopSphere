import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/core/error/result.dart';
import 'package:shopsphere/features/cart/domain/cart_item.dart';
import 'package:shopsphere/features/products/domain/product.dart';
import 'package:shopsphere/features/products/domain/products_repository.dart';

void main() {
  const product = Product(
    id: 7,
    title: 'Headphones',
    description: 'Comfortable over-ear headphones',
    price: 100,
    discountPercentage: 15,
    rating: 4.5,
    stock: 3,
    thumbnail: 'https://example.com/image.jpg',
    images: ['https://example.com/image.jpg'],
    category: 'audio',
    brand: 'SphereSound',
  );

  group('Product', () {
    test('parses a product response fixture', () {
      final json =
          jsonDecode(File('test/fixtures/product.json').readAsStringSync())
              as Map<String, dynamic>;

      final parsed = Product.fromJson(json);

      expect(parsed.title, 'Everyday Wireless Headphones');
      expect(parsed.salePrice, closeTo(69.99125, 0.00001));
      expect(parsed.reviews.single.reviewerName, 'Avery');
    });

    test('parses all core fields from JSON', () {
      final parsed = Product.fromJson(product.toJson());

      expect(parsed.id, 7);
      expect(parsed.title, 'Headphones');
      expect(parsed.brand, 'SphereSound');
    });

    test('calculates discounted sale price', () {
      expect(product.salePrice, 85);
    });

    test('reports a positive stock count as available', () {
      expect(product.isInStock, isTrue);
    });

    test('reports zero stock as unavailable', () {
      final unavailable = Product.fromJson({...product.toJson(), 'stock': 0});

      expect(unavailable.isInStock, isFalse);
    });

    test('falls back safely when optional API fields are missing', () {
      final parsed = Product.fromJson({'id': 9, 'title': 'Simple'});

      expect(parsed.price, 0);
      expect(parsed.brand, isNull);
      expect(parsed.images, isEmpty);
    });

    test('parses customer reviews', () {
      final parsed = Product.fromJson({
        ...product.toJson(),
        'reviews': [
          {
            'rating': 4,
            'comment': 'Lovely',
            'reviewerName': 'Ava',
            'date': '2026-01-01',
          },
        ],
      });

      expect(parsed.reviews.single.comment, 'Lovely');
      expect(parsed.reviews.single.rating, 4);
    });

    test('serializes reviews for local cart persistence', () {
      const review = ProductReview(
        rating: 5,
        comment: 'Great',
        reviewerName: 'Sam',
        date: '2026-01-01',
      );

      expect(review.toJson()['reviewerName'], 'Sam');
    });
  });

  group('Cart calculations', () {
    test('calculates one item subtotal', () {
      const item = CartItem(product: product, quantity: 2);

      expect(item.lineSubtotal, 200);
    });

    test('calculates an item discount', () {
      const item = CartItem(product: product, quantity: 2);

      expect(item.lineDiscount, 30);
    });

    test('calculates an item discounted total', () {
      const item = CartItem(product: product, quantity: 2);

      expect(item.lineTotal, 170);
    });

    test('copies an item with a new quantity', () {
      const item = CartItem(product: product, quantity: 1);

      expect(item.copyWith(quantity: 3).quantity, 3);
    });

    test('aggregates cart totals and count', () {
      const other = Product(
        id: 8,
        title: 'Cable',
        description: '',
        price: 20,
        discountPercentage: 0,
        rating: 4,
        stock: 10,
        thumbnail: '',
        images: [],
        category: 'audio',
      );
      final totals = CartTotals.fromItems(const [
        CartItem(product: product, quantity: 2),
        CartItem(product: other, quantity: 1),
      ]);

      expect(totals.subtotal, 220);
      expect(totals.discount, 30);
      expect(totals.total, 190);
      expect(totals.itemCount, 3);
    });

    test('round-trips cart items through local JSON', () {
      const item = CartItem(product: product, quantity: 2);

      final restored = CartItem.fromJson(item.toJson());

      expect(restored.product.id, product.id);
      expect(restored.quantity, 2);
    });
  });

  group('Product sort API mapping', () {
    test('maps low-price sorting to ascending price parameters', () {
      expect(ProductSort.priceAscending.queryParameters, {
        'sortBy': 'price',
        'order': 'asc',
      });
    });

    test('maps top-rated sorting to descending ratings', () {
      expect(ProductSort.rating.queryParameters, {
        'sortBy': 'rating',
        'order': 'desc',
      });
    });

    test('keeps featured requests free of sort parameters', () {
      expect(ProductSort.featured.queryParameters, isEmpty);
    });
  });

  group('Result', () {
    test('runs the success branch for a successful result', () {
      const result = Success<int>(4);

      expect(result.when(success: (value) => value * 2, failure: (_) => 0), 8);
    });

    test('runs the failure branch for an error result', () {
      final result = Error<int>(Failure.validation('Bad input'));

      expect(
        result.when(
          success: (_) => 'ok',
          failure: (failure) => failure.message,
        ),
        'Bad input',
      );
    });
  });
}
