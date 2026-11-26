import 'package:flutter/material.dart';

import '../core/source.dart';
import '../core/store.dart';
import 'downloads_page.dart';
import 'favorites_page.dart';
import 'history_page.dart';
import 'settings_page.dart';

/// 「我的」页：仿 iOS 版把收藏、历史、设置收进一个入口页。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.store, required this.sources});

  final AppStore store;
  final List<ContentSource> sources;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SafeArea(bottom: false, child: const SizedBox(height: 4)),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.auto_stories,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('One Reader', style: theme.textTheme.titleLarge),
                      Text('开源练手版 · 本地内容源', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.favorite_outline),
                      title: const Text('收藏'),
                      subtitle: Text('${store.favoriteCount} 条'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              FavoritesPage(store: store, sources: sources),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('观看历史'),
                      subtitle: Text('${store.history.length} 条'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              HistoryPage(store: store, sources: sources),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: const Text('下载'),
                      subtitle: const Text('多连接分片下载与离线文件'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DownloadsPage(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('设置'),
                      subtitle: const Text('内容源、地址、主题'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              SettingsPage(store: store, sources: sources),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '内容全部来自你选择的内容源（内置示例或自建 HTTP 源），'
                '本项目不接入任何第三方私有接口或付费内容。',
                style: theme.textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
