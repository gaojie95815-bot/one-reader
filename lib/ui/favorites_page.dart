import 'package:flutter/material.dart';

import '../core/source.dart';
import '../core/store.dart';
import 'detail_page.dart';

/// 收藏页：收藏里同时记住来源，点击时用对应内容源重新取详情。
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key, required this.store, required this.sources});

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
      appBar: AppBar(title: const Text('收藏')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final favorites = store.favorites;
          if (favorites.isEmpty) {
            return const Center(child: Text('还没有收藏，去首页点一条吧'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = favorites[index];
              final source = _sourceOf(entry.sourceId);
              return ListTile(
                title: Text(
                  entry.item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${entry.item.kindLabel} · ${entry.item.category}',
                ),
                trailing: IconButton(
                  tooltip: '取消收藏',
                  icon: const Icon(Icons.favorite),
                  onPressed: () =>
                      store.toggleFavorite(entry.sourceId, entry.item),
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
              );
            },
          );
        },
      ),
    );
  }
}
