import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import '../storage/preferences_store.dart';

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final isDark = ref
        .read(preferencesStoreProvider)
        .readBool(PreferencesStore.themeKey);
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await ref
        .read(preferencesStoreProvider)
        .writeBool(PreferencesStore.themeKey, next == ThemeMode.dark);
  }
}

final themeProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
