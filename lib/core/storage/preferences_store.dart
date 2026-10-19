import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PreferencesStore {
  const PreferencesStore(this._preferences);

  static const cartKey = 'cart_items';
  static const themeKey = 'is_dark_theme';
  static const wishlistKey = 'wishlist_ids';
  final SharedPreferences _preferences;

  List<Map<String, dynamic>> readJsonList(String key) {
    final value = _preferences.getString(key);
    if (value == null) return [];
    try {
      return (jsonDecode(value) as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeJsonList(String key, List<Map<String, dynamic>> value) =>
      _preferences.setString(key, jsonEncode(value));

  bool readBool(String key, {bool fallback = false}) =>
      _preferences.getBool(key) ?? fallback;
  Future<void> writeBool(String key, bool value) =>
      _preferences.setBool(key, value);

  int? readInt(String key) => _preferences.getInt(key);
  Future<void> writeInt(String key, int value) =>
      _preferences.setInt(key, value);

  String? readString(String key) => _preferences.getString(key);
  Future<void> writeString(String key, String value) =>
      _preferences.setString(key, value);

  List<int> readIntList(String key) =>
      _preferences
          .getStringList(key)
          ?.map(int.tryParse)
          .whereType<int>()
          .toList() ??
      [];
  Future<void> writeIntList(String key, Iterable<int> value) =>
      _preferences.setStringList(key, value.map((id) => '$id').toList());
}
