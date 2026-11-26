import 'package:flutter/material.dart';

/// 漫画页：纵向连续阅读，图片按宽度铺满。
class ComicPage extends StatelessWidget {
  const ComicPage({super.key, required this.title, required this.images});

  final String title;
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return Image.network(
            images[index],
            fit: BoxFit.fitWidth,
            width: double.infinity,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Container(
                    height: 220,
                    color: scheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
            errorBuilder: (context, error, stack) => Container(
              height: 120,
              color: scheme.surfaceContainerHighest,
              child: Center(child: Text('第 ${index + 1} 页加载失败')),
            ),
          );
        },
      ),
    );
  }
}
