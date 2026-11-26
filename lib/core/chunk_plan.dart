/// 文件分片计算：多连接下载时把总字节切成若干段。
/// 纯 Dart、无副作用，方便单元测试。
class ByteRange {
  const ByteRange(this.start, this.endExclusive);

  final int start;
  final int endExclusive;

  int get length => endExclusive - start;

  bool get isEmpty => endExclusive <= start;

  @override
  String toString() => '[$start, $endExclusive)';
}

/// 把 [totalBytes] 尽量均匀地切成 [parts] 段；段数不会超过字节数。
List<ByteRange> planChunks(int totalBytes, int parts) {
  if (totalBytes <= 0) return const [];
  var count = parts < 1 ? 1 : parts;
  if (count > totalBytes) count = totalBytes;

  final base = totalBytes ~/ count;
  final remainder = totalBytes % count;
  final ranges = <ByteRange>[];
  var offset = 0;
  for (var i = 0; i < count; i++) {
    final size = base + (i < remainder ? 1 : 0);
    ranges.add(ByteRange(offset, offset + size));
    offset += size;
  }
  return ranges;
}
