import 'models.dart';

/// 内容源接口：新源只要实现这三个 getter 和两个方法，
/// 就会出现在「设置 → 内容源」里，界面不用改。
abstract class ContentSource {
  String get id;
  String get name;
  String get description;

  /// 首页列表。
  Future<List<ContentItem>> fetchFeed();

  /// 点进某一条时的正文与媒体地址。
  Future<ContentDetail> fetchDetail(ContentItem item);

  @override
  bool operator ==(Object other) => other is ContentSource && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// 按当前设置构建可用的内容源列表。
typedef SourceBuilder = List<ContentSource> Function();
