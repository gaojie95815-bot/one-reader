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

/// 全局状态：设置、主题、收藏、播放进度。改动即落本地。
class AppStore extends ChangeNotifier {
  AppStore._(this._prefs);

  static const _kSource = 'settings.sourceId';
  static const _kBaseUrl = 'settings.httpBaseUrl';
  static const _kTheme = 'settings.themeMode';
  static const _kFavorites = 'favorites.v1';
  static const _kProgress = 'progress.v1';

  static const defaultBaseUrl = 'http://10.0.2.2:8787';

  /// 开始播放不足 3 秒不记录，避免「点开又退出」污染继续观看。
  static const _minProgressMs = 3000;

  final SharedPreferences _prefs;
  final Map<String, FavoriteEntry> _favorites = {};
  final Map<String, PlayProgress> _progress = {};

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

    _restoreList(prefs, _kFavorites, (json) {
      final entry = FavoriteEntry.fromJson(json);
      store._favorites[entry.key] = entry;
    });
    _restoreList(prefs, _kProgress, (json) {
      final entry = PlayProgress.fromJson(json);
      store._progress[entry.key] = entry;
    });
    return store;
  }

  static void _restoreList(
    SharedPreferences prefs,
    String key,
    void Function(Map<String, dynamic> json) onEntry,
  ) {
    final raw = prefs.getString(key);
    if (raw == null) return;
    try {
      for (final item in jsonDecode(raw) as List) {
        if (item is Map<Object?, Object?>) {
          onEntry(item.cast<String, dynamic>());
        }
      }
    } catch (_) {
      // 数据损坏就当作空，不影响启动。
    }
  }

  // ---------------------------------------------------------------- 收藏

  List<FavoriteEntry> get favorites {
    final list = _favorites.values.toList();
    list.sort((a, b) => a.item.title.compareTo(b.item.title));
    return list;
  }

  int get favoriteCount => _favorites.length;

  bool isFavorite(String sourceId, String itemId) =>
      _favorites.containsKey('$sourceId/$itemId');

  Future<void> toggleFavorite(String sourceId, ContentItem item) async {
    final key = '$sourceId/${item.id}';
    if (_favorites.remove(key) == null) {
      _favorites[key] = FavoriteEntry(sourceId: sourceId, item: item);
    }
    notifyListeners();
    await _prefs.setString(
      _kFavorites,
      jsonEncode(_favorites.values.map((e) => e.toJson()).toList()),
    );
  }

  // ------------------------------------------------------------ 播放进度

  /// 继续观看：看过一部分、还没看完，按最近观看排序。
  List<PlayProgress> get continueWatching {
    final list = _progress.values
        .where((p) => !p.finished && p.positionMs >= _minProgressMs)
        .toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.take(12).toList(growable: false);
  }

  /// 观看历史：全部记录，最近在前。
  List<PlayProgress> get history {
    final list = _progress.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  PlayProgress? progressFor(String sourceId, String itemId) =>
      _progress['$sourceId/$itemId'];

  Future<void> saveProgress({
    required String sourceId,
    required ContentItem item,
    required Duration position,
    required Duration duration,
  }) async {
    final positionMs = position.inMilliseconds;
    final durationMs = duration.inMilliseconds;
    if (durationMs <= 0 || positionMs < _minProgressMs) return;

    final entry = PlayProgress(
      sourceId: sourceId,
      item: item,
      positionMs: positionMs,
      durationMs: durationMs,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _progress[entry.key] = entry;
    notifyListeners();
    await _persistProgress();
  }

  Future<void> removeProgress(String sourceId, String itemId) async {
    final key = '$sourceId/$itemId';
    if (_progress.remove(key) == null) return;
    notifyListeners();
    await _persistProgress();
  }

  Future<void> clearProgress() async {
    if (_progress.isEmpty) return;
    _progress.clear();
    notifyListeners();
    await _persistProgress();
  }

  // ---------------------------------------------------------------- 设置

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

  Future<void> _persistProgress() async {
    await _prefs.setString(
      _kProgress,
      jsonEncode(_progress.values.map((e) => e.toJson()).toList()),
    );
  }
}
