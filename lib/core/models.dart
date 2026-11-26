// 纯 Dart 数据模型：刻意不 import flutter，方便在命令行和单元测试里直接跑。
import 'dart:convert';

/// 内容形态：对齐 iOS 版的图文 / 阅读 / 影视 / 电台 / 写真 / 漫画。
enum ContentKind { article, reading, video, audio, gallery, comic }

ContentKind parseKind(String? raw) => switch (raw) {
  'video' => ContentKind.video,
  'audio' => ContentKind.audio,
  'reading' || 'book' || 'read' => ContentKind.reading,
  'gallery' || 'photo' || 'photos' => ContentKind.gallery,
  'comic' || 'manga' => ContentKind.comic,
  _ => ContentKind.article,
};

String kindToWire(ContentKind kind) => switch (kind) {
  ContentKind.article => 'article',
  ContentKind.reading => 'reading',
  ContentKind.video => 'video',
  ContentKind.audio => 'audio',
  ContentKind.gallery => 'gallery',
  ContentKind.comic => 'comic',
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
    ContentKind.reading => '阅读',
    ContentKind.video => '影视',
    ContentKind.audio => '电台',
    ContentKind.gallery => '写真',
    ContentKind.comic => '漫画',
  };
}

/// 剧集 / 分集（影视与电台共用）。
class Episode {
  const Episode({
    required this.title,
    required this.mediaUrl,
    this.durationLabel,
  });

  final String title;
  final String mediaUrl;
  final String? durationLabel;

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    title: (json['title'] as String?) ?? '',
    mediaUrl: (json['media_url'] as String?) ?? '',
    durationLabel: json['duration'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'media_url': mediaUrl,
    if (durationLabel != null) 'duration': durationLabel,
  };
}

/// 评论：示例数据里给几条，用户也能在本机追加。
class Comment {
  const Comment({
    required this.id,
    required this.author,
    required this.content,
    this.likes = 0,
    this.createdAt = 0,
  });

  final String id;
  final String author;
  final String content;
  final int likes;

  /// 毫秒时间戳；0 表示示例数据。
  final int createdAt;

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: '${json['id'] ?? ''}',
    author: (json['author'] as String?) ?? '匿名',
    content: (json['content'] as String?) ?? '',
    likes: (json['likes'] as num?)?.toInt() ?? 0,
    createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author,
    'content': content,
    'likes': likes,
    'created_at': createdAt,
  };
}

/// 详情页需要的正文、媒体、图集、剧集与评论。
class ContentDetail {
  const ContentDetail({
    required this.item,
    this.body = '',
    this.mediaUrl,
    this.tags = const [],
    this.images = const [],
    this.episodes = const [],
    this.comments = const [],
  });

  final ContentItem item;
  final String body;
  final String? mediaUrl;
  final List<String> tags;

  /// 写真 / 漫画的图片列表。
  final List<String> images;

  /// 影视 / 电台的分集。
  final List<Episode> episodes;

  /// 示例评论（用户评论另外存在本地）。
  final List<Comment> comments;

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
      images: ((json['images'] as List?) ?? const [])
          .map((e) => '$e')
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      episodes: ((json['episodes'] as List?) ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map((e) => Episode.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
      comments: ((json['comments'] as List?) ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map((e) => Comment.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'item': item.toJson(),
    'body': body,
    if (mediaUrl != null) 'media_url': mediaUrl,
    if (tags.isNotEmpty) 'tags': tags,
    if (images.isNotEmpty) 'images': images,
    if (episodes.isNotEmpty)
      'episodes': episodes.map((e) => e.toJson()).toList(),
    if (comments.isNotEmpty)
      'comments': comments.map((e) => e.toJson()).toList(),
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

/// 播放进度：驱动「继续观看」与「观看历史」，纯本地数据。
class PlayProgress {
  const PlayProgress({
    required this.sourceId,
    required this.item,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
  });

  final String sourceId;
  final ContentItem item;
  final int positionMs;
  final int durationMs;

  /// 毫秒时间戳，用来排序。
  final int updatedAt;

  String get key => '$sourceId/${item.id}';

  double get fraction {
    if (durationMs <= 0) return 0;
    return (positionMs / durationMs).clamp(0.0, 1.0);
  }

  /// 看到 97% 以上就算看完，不再出现在「继续观看」里。
  bool get finished => durationMs > 0 && fraction >= 0.97;

  Duration get position => Duration(milliseconds: positionMs);

  factory PlayProgress.fromJson(Map<String, dynamic> json) {
    final rawItem = json['item'];
    return PlayProgress(
      sourceId: (json['source_id'] as String?) ?? 'demo',
      item: ContentItem.fromJson(
        rawItem is Map<Object?, Object?>
            ? rawItem.cast<String, dynamic>()
            : const <String, dynamic>{},
      ),
      positionMs: (json['position_ms'] as num?)?.toInt() ?? 0,
      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'source_id': sourceId,
    'item': item.toJson(),
    'position_ms': positionMs,
    'duration_ms': durationMs,
    'updated_at': updatedAt,
  };
}
