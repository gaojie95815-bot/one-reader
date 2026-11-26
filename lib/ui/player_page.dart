import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

/// 播放页：视频用 video_player 画在页面上，音频只显示封面与进度。
/// 播放地址由内容源给出，本项目不内置任何第三方付费资源。
///
/// 会把进度回报给上层（用于「继续观看」），并从上次位置续播。
class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.title,
    required this.mediaUrl,
    required this.isAudio,
    this.initialPosition = Duration.zero,
    this.onProgress,
  });

  final String title;
  final String mediaUrl;
  final bool isAudio;
  final Duration initialPosition;

  /// 每 4 秒回报一次进度，暂停与退出时也会回报。
  final void Function(Duration position, Duration duration)? onProgress;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? _controller;
  String? _error;
  Timer? _ticker;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.mediaUrl),
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      if (widget.initialPosition > Duration.zero) {
        await controller.seekTo(widget.initialPosition);
      }
      setState(() {});
      await controller.play();
      _ticker = Timer.periodic(const Duration(seconds: 4), (_) => _report());
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    }
  }

  void _report() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    widget.onProgress?.call(
      controller.value.position,
      controller.value.duration,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _report();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(widget.mediaUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('没有找到能打开这个地址的应用')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<double>(
            tooltip: '播放速度',
            initialValue: _speed,
            onSelected: (value) {
              setState(() => _speed = value);
              _controller?.setPlaybackSpeed(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 0.5, child: Text('0.5x')),
              PopupMenuItem(value: 0.75, child: Text('0.75x')),
              PopupMenuItem(value: 1.0, child: Text('1x')),
              PopupMenuItem(value: 1.25, child: Text('1.25x')),
              PopupMenuItem(value: 1.5, child: Text('1.5x')),
              PopupMenuItem(value: 2.0, child: Text('2x')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(child: Text('$_speed x')),
            ),
          ),
          IconButton(
            tooltip: '用外部播放器打开',
            onPressed: _openExternally,
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 12),
                    Text('播放失败：$_error', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _openExternally,
                      child: const Text('用外部播放器打开'),
                    ),
                  ],
                ),
              )
            : controller == null || !controller.value.isInitialized
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!widget.isAudio)
                    AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Icon(Icons.graphic_eq, size: 72),
                    ),
                  const SizedBox(height: 16),
                  _Controls(controller: controller, onSeekDone: _report),
                ],
              ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.controller, required this.onSeekDone});

  final VideoPlayerController controller;
  final VoidCallback onSeekDone;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final duration = value.duration;
        final position = value.position;
        return Column(
          children: [
            Slider(
              value: duration.inMilliseconds == 0
                  ? 0
                  : position.inMilliseconds
                        .clamp(0, duration.inMilliseconds)
                        .toDouble(),
              max: duration.inMilliseconds == 0
                  ? 1
                  : duration.inMilliseconds.toDouble(),
              onChanged: (next) =>
                  controller.seekTo(Duration(milliseconds: next.round())),
              onChangeEnd: (_) => onSeekDone(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_format(position)),
                const SizedBox(width: 16),
                IconButton(
                  iconSize: 48,
                  onPressed: () {
                    if (value.isPlaying) {
                      controller.pause();
                      onSeekDone();
                    } else {
                      controller.play();
                    }
                  },
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                ),
                const SizedBox(width: 16),
                Text(_format(duration)),
              ],
            ),
          ],
        );
      },
    );
  }

  static String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return value.inHours > 0
        ? '${value.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}
