import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/source.dart';
import '../core/store.dart';
import 'detail_page.dart';

/// 首页：仿 iOS 版的分区布局 ——
/// 顶部大标题，下面是「继续观看」横滑卡片，再往下是带分类筛选的「推荐」列表。
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store, required this.source});

  final AppStore store;
  final ContentSource source;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<ContentItem>> _feed;
  String? _category;

  @override
  void initState() {
    super.initState();
    _feed = widget.source.fetchFeed();
  }

  Future<void> _reload() async {
    final next = widget.source.fetchFeed();
    setState(() => _feed = next);
    await next;
  }

  void _open(ContentItem item, List<ContentItem> all) {
    final related = all
        .where((e) => e.id != item.id && e.category == item.category)
        .take(8)
        .toList(growable: false);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailPage(
          store: widget.store,
          source: widget.source,
          item: item,
          related: related,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        return Scaffold(
          body: FutureBuilder<List<ContentItem>>(
            future: _feed,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorView(
                  message: '${snapshot.error}',
                  onRetry: _reload,
                );
              }
              final items = snapshot.data ?? const <ContentItem>[];
              final continued = widget.store.continueWatching;
              final categories = <String>{
                for (final item in items) item.category,
              }.toList(growable: false);
              final visible = _category == null
                  ? items
                  : items.where((e) => e.category == _category).toList();

              return RefreshIndicator(
                onRefresh: _reload,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar.large(
                      title: Text(widget.source.name),
                      actions: [
                        IconButton(
                          tooltip: '刷新',
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    if (continued.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _ContinueSection(
                          entries: continued,
                          onOpen: (entry) => _open(entry.item, items),
                          onRemove: (entry) => widget.store.removeProgress(
                            entry.sourceId,
                            entry.item.id,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: _CategoryChips(
                        categories: categories,
                        selected: _category,
                        onSelected: (value) =>
                            setState(() => _category = value),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          '推荐',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    SliverList.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _RecommendCard(
                          item: visible[index],
                          onTap: () => _open(visible[index], items),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// 「继续观看」横滑卡片。
class _ContinueSection extends StatelessWidget {
  const _ContinueSection({
    required this.entries,
    required this.onOpen,
    required this.onRemove,
  });

  final List<PlayProgress> entries;
  final void Function(PlayProgress entry) onOpen;
  final void Function(PlayProgress entry) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text('继续观看', style: theme.textTheme.titleLarge),
              const Spacer(),
              Text('${entries.length} 条', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        SizedBox(
          height: 156,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _ContinueCard(
                entry: entry,
                onTap: () => onOpen(entry),
                onRemove: () => onRemove(entry),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  final PlayProgress entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 168,
      child: InkWell(
        onTap: onTap,
        onLongPress: onRemove,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 168,
                    height: 100,
                    child: entry.item.coverUrl.isEmpty
                        ? Container(color: scheme.surfaceContainerHighest)
                        : Image.network(
                            entry.item.coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              color: scheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: entry.fraction,
                minHeight: 3,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entry.item.title,
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

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('全部'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: selected == category,
                onSelected: (_) => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}

/// 推荐列表卡片（横图 + 标题 + 摘要）。
class _RecommendCard extends StatelessWidget {
  const _RecommendCard({required this.item, required this.onTap});

  final ContentItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 104,
                  height: 78,
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (item.summary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        _Tag(text: item.kindLabel),
                        _Tag(text: item.category),
                        if (item.durationLabel != null)
                          _Tag(text: item.durationLabel!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: scheme.onSecondaryContainer),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40),
            const SizedBox(height: 12),
            Text('加载失败：$message', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
