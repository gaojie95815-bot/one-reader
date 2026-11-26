import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/downloads.dart';

/// 下载页：多连接下载任务列表，支持取消、删除、复制保存路径。
class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = DownloadManager.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('下载')),
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          final tasks = manager.tasks;
          if (tasks.isEmpty) {
            return const Center(child: Text('还没有下载任务\n在详情页点「下载」即可'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: task.status == DownloadStatus.completed
                          ? 1
                          : task.progress,
                      minHeight: 3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.error == null
                          ? '${downloadStatusLabel(task.status)} · ${_size(task.receivedBytes)}'
                                '${task.totalBytes > 0 ? ' / ${_size(task.totalBytes)}' : ''}'
                          : '${downloadStatusLabel(task.status)} · ${task.error}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (task.isActive)
                      IconButton(
                        tooltip: '取消',
                        icon: const Icon(Icons.stop_circle_outlined),
                        onPressed: () => manager.cancel(task.id),
                      )
                    else if (task.status == DownloadStatus.completed)
                      IconButton(
                        tooltip: '复制保存路径',
                        icon: const Icon(Icons.copy_all_outlined),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: task.filePath),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已复制保存路径')),
                            );
                          }
                        },
                      ),
                    IconButton(
                      tooltip: '删除',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => manager.remove(task.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
