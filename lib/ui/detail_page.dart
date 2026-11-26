import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/source.dart';
import '../core/store.dart';
import 'player_page.dart';

/// 详情页：正文 + 收藏 + 续播 + 相关推荐。
class DetailPage extends StatefulWidget {
  const DetailPage({
    super.key,
    required this.store,
    required this.source,
    required this.item,
    this.related = const [],
  });

  final AppStore store;
  final ContentSource source;
  final ContentItem item;

  /// 同分类的其它条目，由列表页传进来，用来做「相关推荐」。
  final List<ContentItem> related;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<ContentDetail> _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.source.fetchDetail(widget.item);
  }

  void _toggleFavorite() {
    widget.store.toggleFavorite(widget.source.id, widget.item);
  }

  void _play(ContentDetail detail) {
    final mediaUrl = detail.mediaUrl;
    if (mediaUrl == null || mediaUrl.isEmpty) return;

    final progress = widget.store.progressFor(widget.source.id, widget.item.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerPage(
          title: detail.item.title,
          mediaUrl: mediaUrl,
          isAudio: detail.item.kind == ContentKind.audio,
          initialPosition: progress?.position ?? Duration.zero,
          onProgress: (position, duration) => widget.store.saveProgress(
            sourceId: widget.source.id,
            item: widget.item,
            position: position,
            duration: duration,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title, overflow: TextOverflow.ellipsis),
        actions: [
          ListenableBuilder(
            listenable: widget.store,
            builder: (context, _) {
              final favorite = widget.store.isFavorite(
                widget.source.id,
                widget.item.id,
              );
              return IconButton(
                tooltip: favorite ? '取消收藏' : '收藏',
                onPressed: _toggleFavorite,
                icon: Icon(favorite ? Icons.favorite : Icons.favorite_border),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<ContentDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('详情加载失败：${snapshot.error}'));
          }
          final detail = snapshot.data!;
          final progress = widget.store.progressFor(
            widget.source.id,
            widget.item.id,
          );
          final mediaUrl = detail.mediaUrl;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(detail.item.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '${detail.item.kindLabel} · ${detail.item.category}'
                '${detail.item.durationLabel == null ? '' : ' · ${detail.item.durationLabel}'}',
                style: theme.textTheme.bodySmall,
              ),
              if (detail.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: detail.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ContinueCard(progress: progress, onPlay: () => _play(detail)),
              ],
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              SelectableText(
                detail.body.isEmpty ? '（这条内容还没有正文）' : detail.body,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
              if (widget.related.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('相关推荐', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SizedBox(
                  height: 168,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.related.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = widget.related[index];
                      return _RelatedCard(
                        item: item,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DetailPage(
                              store: widget.store,
                              source: widget.source,
                              item: item,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 播放/续播按钮：带上次观看进度。
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.progress, required this.onPlay});

  final PlayProgress? progress;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = progress == null
        ? '播放'
        : progress!.finished
        ? '重新播放'
        : '继续播放 · ${_percent(progress!)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onPlay,
          icon: const Icon(Icons.play_arrow),
          label: Text(label),
        ),
        if (progress != null && !progress!.finished) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress!.fraction,
              minHeight: 4,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '上次看到 ${_mmss(progress!.position)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  static String _percent(PlayProgress progress) =>
      '${(progress.fraction * 100).round()}%';

  static String _mmss(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return value.inHours > 0
        ? '${value.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({required this.item, required this.onTap});

  final ContentItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 100,
                width: 160,
                child: item.coverUrl.isEmpty
                    ? Container(color: scheme.surfaceContainerHighest)
                    : Image.network(
                        item.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: scheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
