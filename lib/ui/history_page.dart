import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/source.dart';
import '../core/store.dart';
import 'detail_page.dart';

/// 观看历史：带进度条，左滑删除，右上角可清空。
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.store, required this.sources});

  final AppStore store;
  final List<ContentSource> sources;

  ContentSource? _sourceOf(String id) {
    for (final source in sources) {
      if (source.id == id) return source;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('观看历史'),
        actions: [
          IconButton(
            tooltip: '清空历史',
            onPressed: store.history.isEmpty
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('清空观看历史？'),
                        content: const Text('所有播放进度会被删除，收藏不受影响。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('清空'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed ?? false) await store.clearProgress();
                  },
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final entries = store.history;
          if (entries.isEmpty) {
            return const Center(child: Text('还没有观看记录'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final source = _sourceOf(entry.sourceId);
              return Dismissible(
                key: ValueKey(entry.key),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Icon(Icons.delete_outline),
                ),
                onDismissed: (_) =>
                    store.removeProgress(entry.sourceId, entry.item.id),
                child: ListTile(
                  leading: _Thumb(item: entry.item),
                  title: Text(
                    entry.item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: entry.fraction,
                        minHeight: 3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.item.kindLabel} · 已看 ${(entry.fraction * 100).round()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  onTap: () {
                    if (source == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('来源 ${entry.sourceId} 已不可用')),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DetailPage(
                          store: store,
                          source: source,
                          item: entry.item,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 48,
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
    );
  }
}
