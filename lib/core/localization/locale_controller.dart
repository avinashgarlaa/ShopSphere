import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final languageCode = ref
        .read(preferencesStoreProvider)
        .readString('language_code');
    return languageCode == 'hi' ? const Locale('hi') : const Locale('en');
  }

  Future<void> setLanguage(String languageCode) async {
    final locale = languageCode == 'hi'
        ? const Locale('hi')
        : const Locale('en');
    state = locale;
    await ref
        .read(preferencesStoreProvider)
        .writeString('language_code', locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
