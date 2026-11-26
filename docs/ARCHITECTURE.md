# 架构说明

## 分层

```
UI (lib/ui)
   │  只依赖 ContentSource 接口与 AppStore
   ▼
状态 (lib/core/store.dart)         设置 / 主题 / 收藏，落 shared_preferences
   │
   ▼
数据源 (lib/sources)   demo_source.dart（assets 离线）  http_json_source.dart（HTTP）
   │
   ▼
模型 (lib/core/models.dart)        纯 Dart，可单测
```

## 数据流

1. `main()` 先 `await AppStore.load()`，把设置读回来再建界面，避免首帧闪烁；
2. `HomeShell` 根据设置的 `sourceId` 构建内容源列表，取当前源；
3. `HomePage` 在 `initState` 里 `fetchFeed()`，`FutureBuilder` 渲染加载/失败/空数据；
4. 点条目进 `DetailPage`，`fetchDetail(item)` 拿正文与 `media_url`；
5. 有媒体地址就进 `PlayerPage`，`video_player` 初始化失败时提供外部播放器兜底；
6. 收藏按 `sourceId/itemId` 存，不同源的同 id 不会互相覆盖。

## 为什么内容源要抽成接口

界面依赖的是「能给我列表、能给我详情」这件事，而不是「从哪拿」。

- 换数据源 = 新增一个实现类，不改任何页面；
- 测试 = 换一个假源，不发网络请求；
- 演进 = 以后接自己的后端、本地数据库、甚至 RSS，都只是再加一个实现。

## 错误处理约定

- 加载中：`CircularProgressIndicator`
- 失败：显示原始错误信息 + 重试按钮（`FutureBuilder` 的 `snapshot.error`）
- 空数据：明确文案，不显示空白页
- 播放失败：显示原因 + 「用外部播放器打开」

## 已知限制（刻意留白，适合作为练习）

- 没有缓存层：每次进页面都重新请求；
- 没有分页：列表一次全量返回；
- 没有播放进度记忆；
- 主题只有一套 seed 色；
- 测试只覆盖模型层。

## 目录约定

- `core/` 放与 UI 无关的东西，尽量能纯 Dart 测试；
- `sources/` 一个文件一个数据源，构造函数注入配置（如 baseUrl）；
- `ui/` 一个文件一个页面，状态尽量往下沉（页面自己管加载状态，全局状态放 AppStore）。
