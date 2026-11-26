import 'package:flutter/material.dart';

/// 阅读模式：长文按段落排版，可调字号，对齐 iOS 版的「阅读」体验。
class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  double _fontSize = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: '缩小字号',
            onPressed: _fontSize <= 14
                ? null
                : () => setState(() => _fontSize -= 2),
            icon: const Icon(Icons.text_decrease),
          ),
          IconButton(
            tooltip: '放大字号',
            onPressed: _fontSize >= 26
                ? null
                : () => setState(() => _fontSize += 2),
            icon: const Icon(Icons.text_increase),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(widget.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          SelectableText(
            widget.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: _fontSize,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}
