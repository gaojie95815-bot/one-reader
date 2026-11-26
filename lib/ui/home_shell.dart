import 'package:flutter/material.dart';

import '../core/source.dart';
import '../core/store.dart';
import '../sources/demo_source.dart';
import '../sources/http_json_source.dart';
import 'favorites_page.dart';
import 'home_page.dart';
import 'settings_page.dart';

/// 首页外壳：底部三个页签 + 根据设置构建内容源。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});

  final AppStore store;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  List<ContentSource> get _sources => [
    DemoSource(),
    HttpJsonSource(baseUrl: widget.store.httpBaseUrl),
  ];

  ContentSource get _currentSource {
    final sources = _sources;
    return sources.firstWhere(
      (source) => source.id == widget.store.sourceId,
      orElse: () => sources.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final source = _currentSource;
        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              HomePage(
                key: ValueKey('home-${source.id}-${widget.store.httpBaseUrl}'),
                store: widget.store,
                source: source,
              ),
              FavoritesPage(store: widget.store, sources: _sources),
              SettingsPage(store: widget.store, sources: _sources),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: '首页',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: '收藏',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: '设置',
              ),
            ],
          ),
        );
      },
    );
  }
}
