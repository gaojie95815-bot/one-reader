import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../core/models.dart';
import '../core/source.dart';

/// 内置离线示例源：数据打包在 assets/demo/feed.json 里，断网也能跑。
/// 适合先跑通界面，再换 HttpJsonSource 看网络请求。
class DemoSource implements ContentSource {
  FeedPayload? _cache;

  @override
  String get id => 'demo';

  @override
  String get name => '内置示例';

  @override
  String get description => '打包在 assets 里的离线示例数据，先用来学习界面结构。';

  @override
  Future<List<ContentItem>> fetchFeed() async => (await _load()).items;

  @override
  Future<ContentDetail> fetchDetail(ContentItem item) async {
    final detail = (await _load()).details[item.id];
    if (detail == null) {
      throw StateError('示例数据缺少条目 ${item.id}');
    }
    return detail;
  }

  Future<FeedPayload> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/demo/feed.json');
    return _cache = FeedPayload.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}
