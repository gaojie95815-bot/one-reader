import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/source.dart';
import '../core/store.dart';
import 'player_page.dart';

/// 详情页：正文 + 收藏 + 播放（有 media_url 时）。
class DetailPage extends StatefulWidget {
  const DetailPage({
    super.key,
    required this.store,
    required this.source,
    required this.item,
  });

  final AppStore store;
  final ContentSource source;
  final ContentItem item;

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
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlayerPage(
                        title: detail.item.title,
                        mediaUrl: mediaUrl,
                        isAudio: detail.item.kind == ContentKind.audio,
                      ),
                    ),
                  ),
                  icon: Icon(
                    detail.item.kind == ContentKind.audio
                        ? Icons.headphones
                        : Icons.play_circle_outline,
                  ),
                  label: Text(
                    detail.item.kind == ContentKind.audio ? '收听' : '播放',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              SelectableText(
                detail.body.isEmpty ? '（这条内容还没有正文）' : detail.body,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ],
          );
        },
      ),
    );
  }
}
