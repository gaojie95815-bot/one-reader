import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:one_reader/core/models.dart';

const _sample = '''
{
  "source": "demo",
  "items": [
    {"id": "a1", "title": "标题", "summary": "摘要", "cover_url": "https://example.com/a.jpg", "category": "随笔", "kind": "article"},
    {"id": "v1", "title": "视频", "kind": "video", "duration": "0:07"},
    {"id": "x1", "title": "未知类型"}
  ],
  "details": {
    "a1": {"item": {"id": "a1", "title": "标题"}, "body": "正文", "tags": ["tag-1"]},
    "v1": {"item": {"id": "v1", "title": "视频"}, "media_url": "https://example.com/v.mp4"}
  }
}
''';

void main() {
  _playProgressTests();

  test('解析列表与详情', () {
    final payload = FeedPayload.decode(_sample);
    expect(payload.sourceName, 'demo');
    expect(payload.items.length, 3);
    expect(payload.items.first.title, '标题');
    expect(payload.items.first.kind, ContentKind.article);
    expect(payload.items[1].kind, ContentKind.video);
    expect(payload.items[1].durationLabel, '0:07');
    expect(payload.details['a1']?.body, '正文');
    expect(payload.details['a1']?.tags, ['tag-1']);
    expect(payload.details['v1']?.mediaUrl, 'https://example.com/v.mp4');
  });

  test('未知 kind 归为图文', () {
    final payload = FeedPayload.decode(_sample);
    expect(payload.items.last.kind, ContentKind.article);
  });

  test('ContentItem 往返序列化', () {
    const item = ContentItem(
      id: 'v1',
      title: '视频',
      summary: '简介',
      coverUrl: 'https://example.com/c.jpg',
      category: '示例',
      kind: ContentKind.video,
      durationLabel: '1:00',
    );
    final restored = ContentItem.fromJson(
      jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>,
    );
    expect(restored.id, item.id);
    expect(restored.title, item.title);
    expect(restored.summary, item.summary);
    expect(restored.coverUrl, item.coverUrl);
    expect(restored.kind, ContentKind.video);
    expect(restored.durationLabel, '1:00');
  });
}

void _playProgressTests() {
  test('PlayProgress 进度与完成判定', () {
    const item = ContentItem(id: 'v1', title: '视频');
    final halfway = PlayProgress(
      sourceId: 'demo',
      item: item,
      positionMs: 30000,
      durationMs: 60000,
      updatedAt: 1,
    );
    expect(halfway.key, 'demo/v1');
    expect(halfway.fraction, closeTo(0.5, 0.001));
    expect(halfway.finished, isFalse);

    final almostDone = PlayProgress(
      sourceId: 'demo',
      item: item,
      positionMs: 59000,
      durationMs: 60000,
      updatedAt: 2,
    );
    expect(almostDone.finished, isTrue);

    final restored = PlayProgress.fromJson(
      jsonDecode(jsonEncode(almostDone.toJson())) as Map<String, dynamic>,
    );
    expect(restored.positionMs, 59000);
    expect(restored.durationMs, 60000);
    expect(restored.sourceId, 'demo');
  });

  test('duration 为 0 时进度为 0', () {
    const item = ContentItem(id: 'v2', title: '视频');
    final entry = PlayProgress(
      sourceId: 'demo',
      item: item,
      positionMs: 1000,
      durationMs: 0,
      updatedAt: 0,
    );
    expect(entry.fraction, 0);
    expect(entry.finished, isFalse);
  });
}
