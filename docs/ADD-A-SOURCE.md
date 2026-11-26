# 新增一个内容源

目标：让 App 首页能列出、详情能打开你自己的一套内容。

## 第一步：写实现类

新建 `lib/sources/my_source.dart`：

```dart
import '../core/models.dart';
import '../core/source.dart';

class MySource implements ContentSource {
  MySource({required this.endpoint});

  final String endpoint;

  @override
  String get id => 'my_source';

  @override
  String get name => '我的内容源';

  @override
  String get description => '从 $endpoint 读取内容';

  @override
  Future<List<ContentItem>> fetchFeed() async {
    // TODO: 请求 endpoint，解析成 ContentItem 列表
    return const [
      ContentItem(id: '1', title: '第一条'),
    ];
  }

  @override
  Future<ContentDetail> fetchDetail(ContentItem item) async {
    // TODO: 按 item.id 取详情
    return ContentDetail(item: item, body: '正文');
  }
}
```

## 第二步：注册到设置页

编辑 `lib/ui/home_shell.dart` 的 `_sources`：

```dart
List<ContentSource> get _sources => [
      DemoSource(),
      HttpJsonSource(baseUrl: widget.store.httpBaseUrl),
      MySource(endpoint: 'https://example.com'),
    ];
```

设置页会自动多一个选项，界面不用改。

## 第三步：验证

1. `flutter test` 跑一遍；
2. `flutter run` 进设置切到新源，回首页下拉刷新；
3. 断网、改错地址各试一次，确认错误界面和重试正常。

## 约定与注意

- `fetchFeed` / `fetchDetail` 里自己处理超时（推荐 10–15 秒）并把异常往上抛，界面会显示原始错误；
- `id` 必须稳定且全局唯一到「这个源内部」，收藏按 `sourceId/itemId` 存；
- 不要在源里写死 UI 逻辑（弹窗、导航），它是纯数据层；
- 数据来源必须是你拥有版权或已获授权的，不要抓第三方平台私有接口或绕过付费。
