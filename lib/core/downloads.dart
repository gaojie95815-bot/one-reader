import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'chunk_plan.dart';

enum DownloadStatus { queued, running, completed, failed, cancelled }

String downloadStatusLabel(DownloadStatus status) => switch (status) {
  DownloadStatus.queued => '排队中',
  DownloadStatus.running => '下载中',
  DownloadStatus.completed => '已完成',
  DownloadStatus.failed => '失败',
  DownloadStatus.cancelled => '已取消',
};

/// 一个下载任务：多连接分片下载 + 进度。
class DownloadTask {
  DownloadTask({
    required this.id,
    required this.sourceId,
    required this.itemId,
    required this.title,
    required this.mediaUrl,
    required this.filePath,
  });

  final String id;
  final String sourceId;
  final String itemId;
  final String title;
  final String mediaUrl;
  final String filePath;

  int totalBytes = 0;
  int receivedBytes = 0;
  DownloadStatus status = DownloadStatus.queued;
  String? error;

  bool _cancelRequested = false;

  double get progress =>
      totalBytes <= 0 ? 0 : (receivedBytes / totalBytes).clamp(0.0, 1.0);

  bool get isActive =>
      status == DownloadStatus.queued || status == DownloadStatus.running;

  Map<String, dynamic> toJson() => {
    'id': id,
    'source_id': sourceId,
    'item_id': itemId,
    'title': title,
    'media_url': mediaUrl,
    'file_path': filePath,
    'total_bytes': totalBytes,
    'received_bytes': receivedBytes,
    'status': status.name,
  };

  factory DownloadTask.fromJson(Map<String, dynamic> json) =>
      DownloadTask(
          id: '${json['id']}',
          sourceId: (json['source_id'] as String?) ?? 'demo',
          itemId: (json['item_id'] as String?) ?? '',
          title: (json['title'] as String?) ?? '未命名',
          mediaUrl: (json['media_url'] as String?) ?? '',
          filePath: (json['file_path'] as String?) ?? '',
        )
        ..totalBytes = (json['total_bytes'] as num?)?.toInt() ?? 0
        ..receivedBytes = (json['received_bytes'] as num?)?.toInt() ?? 0
        ..status = DownloadStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DownloadStatus.queued,
        );
}

/// 下载管理器：单例，页面直接取 `DownloadManager.instance`。
/// 用单例是为了避免把管理器一层层传进「详情 / 收藏 / 历史 / 播放器」。
class DownloadManager extends ChangeNotifier {
  DownloadManager._(this._dir, this._tasks);

  static const maxConnections = 4;
  static const _metaFile = 'tasks.json';

  static DownloadManager? _instance;

  static DownloadManager get instance {
    final value = _instance;
    if (value == null) {
      throw StateError('DownloadManager 还没有初始化，先调用 DownloadManager.init()');
    }
    return value;
  }

  static Future<DownloadManager> init() async {
    if (_instance != null) return _instance!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/downloads');
    await dir.create(recursive: true);

    final tasks = <DownloadTask>[];
    final meta = File('${dir.path}/$_metaFile');
    if (await meta.exists()) {
      try {
        final raw = jsonDecode(await meta.readAsString()) as List;
        for (final item in raw) {
          if (item is Map<Object?, Object?>) {
            final task = DownloadTask.fromJson(item.cast<String, dynamic>());
            // 上次进程退出时还在下载的，标记为失败，避免假装在跑。
            if (task.isActive) {
              task.status = DownloadStatus.failed;
              task.error = '上次未完成';
            }
            tasks.add(task);
          }
        }
      } catch (_) {
        // 元数据损坏就当作空列表。
      }
    }

    return _instance = DownloadManager._(dir, tasks);
  }

  final Directory _dir;
  final List<DownloadTask> _tasks;

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  List<DownloadTask> get active =>
      _tasks.where((t) => t.isActive).toList(growable: false);

  bool isDownloaded(String sourceId, String itemId) => _tasks.any(
    (t) =>
        t.sourceId == sourceId &&
        t.itemId == itemId &&
        t.status == DownloadStatus.completed,
  );

  DownloadTask? taskOf(String sourceId, String itemId) {
    for (final task in _tasks) {
      if (task.sourceId == sourceId && task.itemId == itemId) return task;
    }
    return null;
  }

  Future<DownloadTask> enqueue({
    required String sourceId,
    required String itemId,
    required String title,
    required String mediaUrl,
  }) async {
    final existing = taskOf(sourceId, itemId);
    if (existing != null) {
      if (existing.status != DownloadStatus.completed)
        unawaited(_run(existing));
      return existing;
    }

    final id = '${sourceId}_$itemId';
    final task = DownloadTask(
      id: id,
      sourceId: sourceId,
      itemId: itemId,
      title: title,
      mediaUrl: mediaUrl,
      filePath: '${_dir.path}/$id.bin',
    );
    _tasks.add(task);
    notifyListeners();
    await _persist();
    unawaited(_run(task));
    return task;
  }

  Future<void> cancel(String id) async {
    for (final task in _tasks) {
      if (task.id == id && task.isActive) {
        task._cancelRequested = true;
        await _cleanupParts(task);
        task.status = DownloadStatus.cancelled;
        task.error = null;
        notifyListeners();
        await _persist();
      }
    }
  }

  Future<void> remove(String id) async {
    final task = _tasks.firstWhere((t) => t.id == id, orElse: () => _missing);
    if (identical(task, _missing)) return;
    task._cancelRequested = true;
    await _cleanupParts(task);
    await _deleteIfExists(File(task.filePath));
    _tasks.remove(task);
    notifyListeners();
    await _persist();
  }

  static final DownloadTask _missing = DownloadTask(
    id: '',
    sourceId: '',
    itemId: '',
    title: '',
    mediaUrl: '',
    filePath: '',
  );

  Future<void> _run(DownloadTask task) async {
    if (task.status == DownloadStatus.running) return;
    task._cancelRequested = false;
    task.status = DownloadStatus.running;
    task.error = null;
    task.receivedBytes = 0;
    task.totalBytes = 0;
    notifyListeners();

    final client = http.Client();
    final parts = <File>[];
    try {
      final total = await _probeTotal(client, task.mediaUrl);
      if (task._cancelRequested) return;

      if (total <= 0) {
        await _downloadSingleStream(client, task);
      } else {
        task.totalBytes = total;
        notifyListeners();

        final ranges = planChunks(total, maxConnections);
        for (var i = 0; i < ranges.length; i++) {
          parts.add(File('${task.filePath}.part$i'));
        }

        await Future.wait([
          for (var i = 0; i < ranges.length; i++)
            _downloadChunk(client, task, ranges[i], parts[i]),
        ]);

        final output = File(task.filePath);
        final sink = output.openWrite();
        try {
          for (final part in parts) {
            await sink.addStream(part.openRead());
          }
        } finally {
          await sink.close();
        }
      }

      if (task._cancelRequested) return;
      task.status = DownloadStatus.completed;
      task.receivedBytes = task.totalBytes;
      notifyListeners();
      await _persist();
      await _cleanupParts(task);
    } catch (error) {
      if (task._cancelRequested) return;
      task.status = DownloadStatus.failed;
      task.error = '$error';
      notifyListeners();
      await _persist();
    } finally {
      client.close();
      for (final part in parts) {
        await _deleteIfExists(part);
      }
    }
  }

  Future<int> _probeTotal(http.Client client, String url) async {
    final request = http.Request('GET', Uri.parse(url))
      ..headers['Range'] = 'bytes=0-0';
    final response = await client.send(request);
    final contentRange = response.headers['content-range'];
    await response.stream.drain<void>();
    if (response.statusCode == 206 && contentRange != null) {
      final total = contentRange.split('/').last.trim();
      return int.tryParse(total) ?? 0;
    }
    final length = response.headers['content-length'];
    if (response.statusCode == 200 && length != null) {
      return int.tryParse(length) ?? 0;
    }
    return 0;
  }

  Future<void> _downloadChunk(
    http.Client client,
    DownloadTask task,
    ByteRange range,
    File part,
  ) async {
    final request = http.Request('GET', Uri.parse(task.mediaUrl))
      ..headers['Range'] = 'bytes=${range.start}-${range.endExclusive - 1}';
    final response = await client.send(request);
    // 服务器忽略 Range 直接回 200 时，只有单段（整文件）可以接受。
    if (response.statusCode == 200 &&
        (range.start != 0 || range.length != task.totalBytes)) {
      throw HttpException('服务器不支持分段下载');
    }
    if (response.statusCode != 206 && response.statusCode != 200) {
      throw HttpException('分片请求失败：HTTP ${response.statusCode}');
    }
    final sink = part.openWrite();
    try {
      await for (final chunk in response.stream) {
        if (task._cancelRequested) return;
        sink.add(chunk);
        task.receivedBytes += chunk.length;
        _notifyThrottled();
      }
    } finally {
      await sink.close();
    }
  }

  Future<void> _downloadSingleStream(
    http.Client client,
    DownloadTask task,
  ) async {
    final response = await client.send(
      http.Request('GET', Uri.parse(task.mediaUrl)),
    );
    if (response.statusCode != 200) {
      throw HttpException('下载失败：HTTP ${response.statusCode}');
    }
    final sink = File(task.filePath).openWrite();
    try {
      await for (final chunk in response.stream) {
        if (task._cancelRequested) return;
        sink.add(chunk);
        task.receivedBytes += chunk.length;
        task.totalBytes = task.receivedBytes;
        _notifyThrottled();
      }
    } finally {
      await sink.close();
    }
  }

  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);

  void _notifyThrottled() {
    final now = DateTime.now();
    if (now.difference(_lastNotify).inMilliseconds < 200) return;
    _lastNotify = now;
    notifyListeners();
  }

  Future<void> _cleanupParts(DownloadTask task) async {
    final dir = _dir;
    try {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.startsWith('${task.filePath}.part')) {
          await _deleteIfExists(entity);
        }
      }
    } catch (_) {
      // 清理失败不影响主流程。
    }
  }

  Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // 忽略。
    }
  }

  Future<void> _persist() async {
    try {
      final meta = File('${_dir.path}/$_metaFile');
      await meta.writeAsString(
        jsonEncode(_tasks.map((t) => t.toJson()).toList()),
      );
    } catch (_) {
      // 落盘失败不阻塞界面。
    }
  }
}
