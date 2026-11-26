import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/source.dart';
import '../core/store.dart';
import 'detail_page.dart';

/// 发现页：按分类浏览 + 关键词搜索。
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key, required this.store, required this.source});

  final AppStore store;
  final ContentSource source;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  late Future<List<ContentItem>> _feed;
  final TextEditingController _query = TextEditingController();
  String? _category;

  @override
  void initState() {
    super.initState();
    _feed = widget.source.fetchFeed();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _open(ContentItem item, List<ContentItem> all) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailPage(
          store: widget.store,
          source: widget.source,
          item: item,
          related: all
              .where((e) => e.id != item.id && e.category == item.category)
              .take(8)
              .toList(growable: false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<ContentItem>>(
          future: _feed,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <ContentItem>[];
            final categories = <String>{for (final item in items) item.category}
                .toList(growable: false);
            final keyword = _query.text.trim();
            final filtered = items
                .where((item) {
                  final matchCategory =
                      _category == null || item.category == _category;
                  final matchKeyword =
                      keyword.isEmpty ||
                      item.title.contains(keyword) ||
                      item.summary.contains(keyword) ||
                      item.category.contains(keyword);
                  return matchCategory && matchKeyword;
                })
                .toList(growable: false);

            return CustomScrollView(
              slivers: [
                SliverAppBar.large(title: const Text('发现')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SearchBar(
                      controller: _query,
                      hintText: '搜索标题、摘要或分类',
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (_query.text.isNotEmpty)
                          IconButton(
                            tooltip: '清空',
                            onPressed: () => setState(_query.clear),
                            icon: const Icon(Icons.close),
                          ),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('全部'),
                            selected: _category == null,
                            onSelected: (_) => setState(() => _category = null),
                          ),
                        ),
                        for (final category in categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: _category == category,
                              onSelected: (_) =>
                                  setState(() => _category = category),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (snapshot.connectionState != ConnectionState.done)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (snapshot.hasError)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('加载失败：${snapshot.error}'),
                    ),
                  )
                else if (filtered.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('没有匹配的内容')),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _GridCard(
                        item: filtered[index],
                        onTap: () => _open(filtered[index], items),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.item, required this.onTap});

  final ContentItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.expand(
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
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            '${item.kindLabel} · ${item.category}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
