import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/models.dart';
import '../core/source.dart';

/// 通用 HTTP JSON 源：GET {baseUrl}/feed、GET {baseUrl}/item/{id}。
///
/// 字段格式见 README「内容源 JSON 格式」。配合 scripts/mock_server.py
/// 可以完全不碰任何真实接口就把网络链路跑通。
class HttpJsonSource implements ContentSource {
  HttpJsonSource({required this.baseUrl});

  final String baseUrl;

  @override
  String get id => 'http';

  @override
  String get name => 'HTTP 通用源';

  @override
  String get description => '从 $baseUrl 读取 JSON 的通用源，字段格式与内置示例一致。';

  @override
  Future<List<ContentItem>> fetchFeed() async {
    final data = await _getJson('/feed');
    return FeedPayload.fromJson(data).items;
  }

  @override
  Future<ContentDetail> fetchDetail(ContentItem item) async {
    final data = await _getJson('/item/${Uri.encodeComponent(item.id)}');
    final raw = data['detail'] ?? data;
    if (raw is! Map<Object?, Object?>) {
      throw FormatException('详情接口返回格式不对：$raw');
    }
    return ContentDetail.fromJson(raw.cast<String, dynamic>());
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$base$path');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw HttpException('GET $uri 返回 HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<Object?, Object?>) {
      throw FormatException('GET $uri 返回的不是 JSON 对象');
    }
    return decoded.cast<String, dynamic>();
  }
}

class HttpException implements Exception {
  HttpException(this.message);

  final String message;

  @override
  String toString() => message;
}
