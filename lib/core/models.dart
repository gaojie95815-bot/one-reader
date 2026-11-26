// 纯 Dart 数据模型：刻意不 import flutter，方便在命令行和单元测试里直接跑。
import 'dart:convert';

/// 内容类型：图文 / 视频 / 电台。
enum ContentKind { article, video, audio }

ContentKind parseKind(String? raw) {
  switch (raw) {
    case 'video':
      return ContentKind.video;
    case 'audio':
      return ContentKind.audio;
    default:
      return ContentKind.article;
  }
}

String kindToWire(ContentKind kind) => switch (kind) {
  ContentKind.article => 'article',
  ContentKind.video => 'video',
  ContentKind.audio => 'audio',
};

/// 列表里的一条内容。
class ContentItem {
  const ContentItem({
    required this.id,
    required this.title,
    this.summary = '',
    this.coverUrl = '',
    this.category = '未分类',
    this.kind = ContentKind.article,
    this.durationLabel,
  });

  final String id;
  final String title;
  final String summary;
  final String coverUrl;
  final String category;
  final ContentKind kind;
  final String? durationLabel;

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
    id: '${json['id'] ?? ''}',
    title: (json['title'] as String?) ?? '',
    summary: (json['summary'] as String?) ?? '',
    coverUrl: (json['cover_url'] as String?) ?? '',
    category: (json['category'] as String?) ?? '未分类',
    kind: parseKind(json['kind'] as String?),
    durationLabel: json['duration'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'cover_url': coverUrl,
    'category': category,
    'kind': kindToWire(kind),
    if (durationLabel != null) 'duration': durationLabel,
  };

  String get kindLabel => switch (kind) {
    ContentKind.article => '图文',
    ContentKind.video => '视频',
    ContentKind.audio => '电台',
  };
}

/// 详情页需要的正文与媒体地址。
class ContentDetail {
  const ContentDetail({
    required this.item,
    this.body = '',
    this.mediaUrl,
    this.tags = const [],
  });

  final ContentItem item;
  final String body;
  final String? mediaUrl;
  final List<String> tags;

  factory ContentDetail.fromJson(Map<String, dynamic> json) {
    final rawItem = json['item'];
    return ContentDetail(
      item: ContentItem.fromJson(
        rawItem is Map<Object?, Object?>
            ? rawItem.cast<String, dynamic>()
            : const <String, dynamic>{},
      ),
      body: (json['body'] as String?) ?? '',
      mediaUrl: json['media_url'] as String?,
      tags: ((json['tags'] as List?) ?? const [])
          .map((e) => '$e')
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'item': item.toJson(),
    'body': body,
    if (mediaUrl != null) 'media_url': mediaUrl,
    if (tags.isNotEmpty) 'tags': tags,
  };
}

/// 一个内容源返回的「列表 + 详情」整包数据。
class FeedPayload {
  const FeedPayload({
    required this.sourceName,
    required this.items,
    required this.details,
  });

  final String sourceName;
  final List<ContentItem> items;
  final Map<String, ContentDetail> details;

  factory FeedPayload.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    final items = rawItems
        .whereType<Map<Object?, Object?>>()
        .map((e) => ContentItem.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);

    final rawDetails = (json['details'] as Map?) ?? const {};
    final details = <String, ContentDetail>{};
    rawDetails.forEach((key, value) {
      if (value is Map<Object?, Object?>) {
        details['$key'] = ContentDetail.fromJson(value.cast<String, dynamic>());
      }
    });

    return FeedPayload(
      sourceName: (json['source'] as String?) ?? 'demo',
      items: items,
      details: details,
    );
  }

  factory FeedPayload.decode(String rawText) =>
      FeedPayload.fromJson(jsonDecode(rawText) as Map<String, dynamic>);
}
