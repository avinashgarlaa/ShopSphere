import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsphere/core/di/providers.dart';
import 'package:shopsphere/core/localization/locale_controller.dart';
import 'package:shopsphere/core/theme/theme_controller.dart';
import 'package:shopsphere/features/products/domain/product.dart';

void main() {
  Future<SharedPreferences> preferencesFor(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  ProviderContainer containerFor(SharedPreferences preferences) =>
      ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );

  test('theme choice persists after the app is recreated', () async {
    final preferences = await preferencesFor({});
    final firstApp = containerFor(preferences);
    addTearDown(firstApp.dispose);

    expect(firstApp.read(themeProvider), ThemeMode.light);
    await firstApp.read(themeProvider.notifier).toggle();
    expect(firstApp.read(themeProvider), ThemeMode.dark);

    final restoredApp = containerFor(preferences);
    addTearDown(restoredApp.dispose);
    expect(restoredApp.read(themeProvider), ThemeMode.dark);
  });

  test(
    'Hindi language selection persists after the app is recreated',
    () async {
      final preferences = await preferencesFor({});
      final firstApp = containerFor(preferences);
      addTearDown(firstApp.dispose);

      expect(firstApp.read(localeProvider), const Locale('en'));
      await firstApp.read(localeProvider.notifier).setLanguage('hi');
      expect(firstApp.read(localeProvider), const Locale('hi'));

      final restoredApp = containerFor(preferences);
      addTearDown(restoredApp.dispose);
      expect(restoredApp.read(localeProvider), const Locale('hi'));
    },
  );

  test('wishlist products persist after the app is recreated', () async {
    const product = Product(
      id: 42,
      title: 'Saved headphones',
      description: '',
      price: 99,
      discountPercentage: 0,
      rating: 4.5,
      stock: 3,
      thumbnail: '',
      images: [],
      category: 'audio',
    );
    final preferences = await preferencesFor({});
    final firstApp = containerFor(preferences);
    addTearDown(firstApp.dispose);

    await firstApp.read(wishlistProvider.notifier).toggle(product);
    expect(firstApp.read(wishlistProvider)[product.id], product);

    final restoredApp = containerFor(preferences);
    addTearDown(restoredApp.dispose);
    expect(
      restoredApp.read(wishlistProvider)[product.id]?.title,
      product.title,
    );
  });
}
