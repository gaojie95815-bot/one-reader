import 'package:flutter/material.dart';

import '../core/source.dart';
import '../core/store.dart';

/// 设置页：切换内容源、配置 HTTP 源地址、主题、项目说明。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store, required this.sources});

  final AppStore store;
  final List<ContentSource> sources;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _baseUrl = TextEditingController(
    text: widget.store.httpBaseUrl,
  );

  @override
  void dispose() {
    _baseUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final store = widget.store;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('内容源', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final source in widget.sources)
                RadioListTile<String>(
                  value: source.id,
                  groupValue: store.sourceId,
                  onChanged: (value) {
                    if (value != null) store.setSource(value);
                  },
                  title: Text(source.name),
                  subtitle: Text(source.description),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _baseUrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'HTTP 源地址',
                  hintText: AppStore.defaultBaseUrl,
                  helperText: 'Android 模拟器访问电脑用 10.0.2.2；真机用电脑局域网 IP',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton(
                    onPressed: () async {
                      await store.setHttpBaseUrl(_baseUrl.text);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已保存：${store.httpBaseUrl}')),
                      );
                    },
                    child: const Text('保存地址'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      _baseUrl.text = AppStore.defaultBaseUrl;
                    },
                    child: const Text('恢复默认'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('主题', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('跟随系统')),
                  ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
                ],
                selected: {store.themeMode},
                onSelectionChanged: (selection) {
                  store.setThemeMode(selection.first);
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text('关于', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'One Reader 是一个开源的 Flutter 练手项目：界面、数据源、收藏、播放都从零实现，'
                '只使用 DemoSource 与自定义 HTTP 源，不接入任何第三方私有接口或付费内容。'
                '想加自己的源，看 docs/ADD-A-SOURCE.md。',
                style: theme.textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
