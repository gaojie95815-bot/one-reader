import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// 收藏条目：记住它来自哪个内容源，避免不同源的 id 撞车。
class FavoriteEntry {
  const FavoriteEntry({required this.sourceId, required this.item});

  final String sourceId;
  final ContentItem item;

  String get key => '$sourceId/${item.id}';

  Map<String, dynamic> toJson() => {
    'source_id': sourceId,
    'item': item.toJson(),
  };

  factory FavoriteEntry.fromJson(Map<String, dynamic> json) {
    final rawItem = json['item'];
    return FavoriteEntry(
      sourceId: (json['source_id'] as String?) ?? 'demo',
      item: ContentItem.fromJson(
        rawItem is Map<Object?, Object?>
            ? rawItem.cast<String, dynamic>()
            : const <String, dynamic>{},
      ),
    );
  }
}

/// 全局状态：当前内容源、自定义源地址、主题、收藏。改动即落本地。
class AppStore extends ChangeNotifier {
  AppStore._(this._prefs);

  static const _kSource = 'settings.sourceId';
  static const _kBaseUrl = 'settings.httpBaseUrl';
  static const _kTheme = 'settings.themeMode';
  static const _kFavorites = 'favorites.v1';

  static const defaultBaseUrl = 'http://10.0.2.2:8787';

  final SharedPreferences _prefs;
  final Map<String, FavoriteEntry> _favorites = {};

  String sourceId = 'demo';
  String httpBaseUrl = defaultBaseUrl;
  ThemeMode themeMode = ThemeMode.system;

  static Future<AppStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore._(prefs);

    store.sourceId = prefs.getString(_kSource) ?? 'demo';
    store.httpBaseUrl = prefs.getString(_kBaseUrl) ?? defaultBaseUrl;
    store.themeMode = switch (prefs.getString(_kTheme)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final raw = prefs.getString(_kFavorites);
    if (raw != null) {
      try {
        for (final item in jsonDecode(raw) as List) {
          if (item is Map<Object?, Object?>) {
            final entry = FavoriteEntry.fromJson(item.cast<String, dynamic>());
            store._favorites[entry.key] = entry;
          }
        }
      } catch (_) {
        // 数据损坏就当作没有收藏，不影响启动。
      }
    }
    return store;
  }

  List<FavoriteEntry> get favorites {
    final list = _favorites.values.toList();
    list.sort((a, b) => a.item.title.compareTo(b.item.title));
    return list;
  }

  bool isFavorite(String sourceId, String itemId) =>
      _favorites.containsKey('$sourceId/$itemId');

  Future<void> toggleFavorite(String sourceId, ContentItem item) async {
    final key = '$sourceId/${item.id}';
    if (_favorites.remove(key) == null) {
      _favorites[key] = FavoriteEntry(sourceId: sourceId, item: item);
    }
    notifyListeners();
    await _persistFavorites();
  }

  Future<void> setSource(String id) async {
    if (sourceId == id) return;
    sourceId = id;
    notifyListeners();
    await _prefs.setString(_kSource, id);
  }

  Future<void> setHttpBaseUrl(String url) async {
    final next = url.trim();
    if (next == httpBaseUrl) return;
    httpBaseUrl = next.isEmpty ? defaultBaseUrl : next;
    notifyListeners();
    await _prefs.setString(_kBaseUrl, httpBaseUrl);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode == mode) return;
    themeMode = mode;
    notifyListeners();
    await _prefs.setString(_kTheme, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  Future<void> _persistFavorites() async {
    await _prefs.setString(
      _kFavorites,
      jsonEncode(_favorites.values.map((e) => e.toJson()).toList()),
    );
  }
}
