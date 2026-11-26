import 'package:flutter/material.dart';

import '../core/source.dart';
import '../core/store.dart';
import '../sources/demo_source.dart';
import '../sources/http_json_source.dart';
import 'discover_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

/// 首页外壳：顶部三个页签（首页 / 发现 / 我的），
/// 对应 iOS 版的「首页 - 发现 - 我的」结构。
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
              DiscoverPage(
                key: ValueKey(
                  'discover-${source.id}-${widget.store.httpBaseUrl}',
                ),
                store: widget.store,
                source: source,
              ),
              ProfilePage(store: widget.store, sources: _sources),
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
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: '发现',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: '我的',
              ),
            ],
          ),
        );
      },
    );
  }
}
