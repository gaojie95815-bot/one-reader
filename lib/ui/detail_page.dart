import 'package:flutter/material.dart';

import '../core/downloads.dart';
import '../core/models.dart';
import '../core/source.dart';
import '../core/store.dart';
import 'comic_page.dart';
import 'downloads_page.dart';
import 'gallery_page.dart';
import 'player_page.dart';
import 'reading_page.dart';

/// 详情页：按内容形态切换呈现 —— 图文 / 阅读 / 影视 / 电台 / 写真 / 漫画，
/// 并补齐评论、下载、续播、相关推荐（对齐 iOS 版的影视详情与图文详情）。
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
  final List<ContentItem> related;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<ContentDetail> _detail;
  final TextEditingController _commentInput = TextEditingController();

  @override
  void initState() {
    super.initState();
    _detail = widget.source.fetchDetail(widget.item);
  }

  @override
  void dispose() {
    _commentInput.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    widget.store.toggleFavorite(widget.source.id, widget.item);
  }

  void _play(ContentDetail detail, {String? mediaUrl, String? episodeTitle}) {
    final url = mediaUrl ?? detail.mediaUrl;
    if (url == null || url.isEmpty) return;
    final progress = widget.store.progressFor(widget.source.id, widget.item.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerPage(
          title: episodeTitle ?? detail.item.title,
          mediaUrl: url,
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

  Future<void> _submitComment(String itemId) async {
    final text = _commentInput.text;
    if (text.trim().isEmpty) return;
    await widget.store.addComment(widget.source.id, itemId, text);
    _commentInput.clear();
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
          final comments = [
            ...widget.store.localComments(widget.source.id, widget.item.id),
            ...detail.comments,
          ];

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _CoverHeader(item: detail.item),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.item.title,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 14),
                    _ActionRow(
                      detail: detail,
                      progress: progress,
                      store: widget.store,
                      sourceId: widget.source.id,
                      onPlay: () => _play(detail),
                      onOpenGallery: () => _openGallery(detail),
                      onOpenComic: () => _openComic(detail),
                      onOpenReading: () => _openReading(detail),
                      onDownload: () => _download(detail),
                      onOpenDownloads: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DownloadsPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (detail.episodes.isNotEmpty) ...[
                const SizedBox(height: 20),
                _EpisodesSection(
                  episodes: detail.episodes,
                  onPlay: (episode) => _play(
                    detail,
                    mediaUrl: episode.mediaUrl,
                    episodeTitle: episode.title,
                  ),
                ),
              ],
              if (detail.images.isNotEmpty &&
                  detail.item.kind == ContentKind.gallery)
                _GalleryPreview(
                  images: detail.images,
                  onOpen: () => _openGallery(detail),
                ),
              if (detail.images.isNotEmpty &&
                  detail.item.kind == ContentKind.comic)
                _ComicPreview(
                  images: detail.images,
                  onOpen: () => _openComic(detail),
                ),
              if (detail.body.isNotEmpty) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 10),
                      SelectableText(
                        detail.body,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                      ),
                    ],
                  ),
                ),
              ],
              _CommentsSection(
                comments: comments,
                controller: _commentInput,
                onSubmit: () => _submitComment(detail.item.id),
              ),
              if (widget.related.isNotEmpty)
                _RelatedSection(
                  items: widget.related,
                  onTap: (item) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DetailPage(
                        store: widget.store,
                        source: widget.source,
                        item: item,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  void _openGallery(ContentDetail detail) {
    if (detail.images.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            GalleryPage(title: detail.item.title, images: detail.images),
      ),
    );
  }

  void _openComic(ContentDetail detail) {
    if (detail.images.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ComicPage(title: detail.item.title, images: detail.images),
      ),
    );
  }

  void _openReading(ContentDetail detail) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ReadingPage(title: detail.item.title, body: detail.body),
      ),
    );
  }

  Future<void> _download(ContentDetail detail) async {
    final firstEpisode = detail.episodes.isEmpty ? null : detail.episodes.first;
    final url = detail.mediaUrl ?? firstEpisode?.mediaUrl;
    if (url == null || url.isEmpty) return;
    await DownloadManager.instance.enqueue(
      sourceId: widget.source.id,
      itemId: widget.item.id,
      title: widget.item.title,
      mediaUrl: url,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已加入下载，去「我的 → 下载」查看')));
  }
}

class _CoverHeader extends StatelessWidget {
  const _CoverHeader({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: item.coverUrl.isEmpty
          ? Container(color: scheme.surfaceContainerHighest)
          : Image.network(
              item.coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                color: scheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined, size: 40),
              ),
            ),
    );
  }
}

/// 主操作区：按内容形态给出不同的第一个按钮。
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.detail,
    required this.progress,
    required this.store,
    required this.sourceId,
    required this.onPlay,
    required this.onOpenGallery,
    required this.onOpenComic,
    required this.onOpenReading,
    required this.onDownload,
    required this.onOpenDownloads,
  });

  final ContentDetail detail;
  final PlayProgress? progress;
  final AppStore store;
  final String sourceId;
  final VoidCallback onPlay;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenComic;
  final VoidCallback onOpenReading;
  final VoidCallback onDownload;
  final VoidCallback onOpenDownloads;

  @override
  Widget build(BuildContext context) {
    final kind = detail.item.kind;
    final hasMedia =
        (detail.mediaUrl != null && detail.mediaUrl!.isNotEmpty) ||
        detail.episodes.isNotEmpty;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (kind == ContentKind.video || kind == ContentKind.audio)
          if (hasMedia)
            FilledButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow),
              label: Text(_playLabel()),
            ),
        if (kind == ContentKind.gallery && detail.images.isNotEmpty)
          FilledButton.icon(
            onPressed: onOpenGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text('看图 · ${detail.images.length} 张'),
          ),
        if (kind == ContentKind.comic && detail.images.isNotEmpty)
          FilledButton.icon(
            onPressed: onOpenComic,
            icon: const Icon(Icons.auto_stories_outlined),
            label: Text('开始阅读 · ${detail.images.length} 页'),
          ),
        if (kind == ContentKind.reading)
          FilledButton.icon(
            onPressed: onOpenReading,
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('阅读模式'),
          ),
        if (hasMedia)
          ListenableBuilder(
            listenable: DownloadManager.instance,
            builder: (context, _) {
              final manager = DownloadManager.instance;
              final task = manager.taskOf(sourceId, detail.item.id);
              final label = switch (task?.status) {
                DownloadStatus.completed => '已下载',
                DownloadStatus.running || DownloadStatus.queued => '下载中…',
                _ => '下载',
              };
              return OutlinedButton.icon(
                onPressed: task?.status == DownloadStatus.completed
                    ? onOpenDownloads
                    : onDownload,
                icon: Icon(
                  task?.status == DownloadStatus.completed
                      ? Icons.download_done
                      : Icons.download_outlined,
                ),
                label: Text(label),
              );
            },
          ),
      ],
    );
  }

  String _playLabel() {
    final p = progress;
    if (p == null) return '播放';
    if (p.finished) return '重新播放';
    return '继续播放 · ${(p.fraction * 100).round()}%';
  }
}

class _EpisodesSection extends StatelessWidget {
  const _EpisodesSection({required this.episodes, required this.onPlay});

  final List<Episode> episodes;
  final void Function(Episode episode) onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Row(
            children: [
              Text('剧集', style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              Text('共 ${episodes.length} 集', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        for (var i = 0; i < episodes.length; i++)
          ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              child: Text('${i + 1}', style: const TextStyle(fontSize: 11)),
            ),
            title: Text(episodes[i].title),
            subtitle: episodes[i].durationLabel == null
                ? null
                : Text(episodes[i].durationLabel!),
            trailing: const Icon(Icons.play_circle_outline),
            onTap: () => onPlay(episodes[i]),
          ),
      ],
    );
  }
}

class _GalleryPreview extends StatelessWidget {
  const _GalleryPreview({required this.images, required this.onOpen});

  final List<String> images;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('图集', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => InkWell(
                onTap: onOpen,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 90,
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          Container(color: scheme.surfaceContainerHighest),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComicPreview extends StatelessWidget {
  const _ComicPreview({required this.images, required this.onOpen});

  final List<String> images;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('试读', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          InkWell(
            onTap: onOpen,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.network(
                  images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: const Center(child: Text('第 1 页加载失败')),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onOpen, child: const Text('继续阅读')),
          ),
        ],
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.comments,
    required this.controller,
    required this.onSubmit,
  });

  final List<Comment> comments;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('评论', style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              Text('${comments.length} 条', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '说点什么…',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: onSubmit, child: const Text('发送')),
            ],
          ),
          const SizedBox(height: 8),
          if (comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('还没有评论', style: theme.textTheme.bodySmall),
            )
          else
            for (final comment in comments)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.author,
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment.createdAt == 0
                              ? '示例评论'
                              : _formatTime(comment.createdAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.content, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  static String _formatTime(int millis) {
    final time = DateTime.fromMillisecondsSinceEpoch(millis);
    final two = (int value) => value.toString().padLeft(2, '0');
    return '${time.month}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
  }
}

class _RelatedSection extends StatelessWidget {
  const _RelatedSection({required this.items, required this.onTap});

  final List<ContentItem> items;
  final void Function(ContentItem item) onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('相关推荐', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  width: 150,
                  child: InkWell(
                    onTap: () => onTap(item),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 96,
                            width: 150,
                            child: item.coverUrl.isEmpty
                                ? Container(
                                    color: scheme.surfaceContainerHighest,
                                  )
                                : Image.network(
                                    item.coverUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) =>
                                        Container(
                                          color: scheme.surfaceContainerHighest,
                                          child: const Icon(
                                            Icons.broken_image_outlined,
                                          ),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
