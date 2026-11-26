# 架构说明

## 分层

```
UI (lib/ui)
   │  只依赖 ContentSource 接口、AppStore、DownloadManager（单例）
   ▼
状态 (lib/core/store.dart)         设置 / 收藏 / 播放进度 / 本地评论
下载 (lib/core/downloads.dart)      分片下载 + 进度 + 任务元数据
   │
   ▼
数据源 (lib/sources)   demo_source.dart（assets 离线）  http_json_source.dart（HTTP）
   │
   ▼
模型 (lib/core/models.dart)        纯 Dart，可单测
      (lib/core/chunk_plan.dart)   分片计算，纯函数
```

## 数据流

1. `main()` 先 `await AppStore.load()` 和 `await DownloadManager.init()`，把本地状态读回来再建界面；
2. `HomeShell` 根据 `sourceId` 构建内容源，三个页签：首页、发现、我的；
3. `HomePage` 拉列表，顶部「继续观看」来自 `AppStore.continueWatching`；
4. `DetailPage` 拉详情，按 `kind` 渲染不同主操作：
   - `reading` → `ReadingPage`（字号可调）
   - `gallery` → `GalleryPage`（PageView + InteractiveViewer）
   - `comic` → `ComicPage`（纵向连续）
   - `video` / `audio` → 剧集列表或直接播放
5. `PlayerPage` 从上次位置续播，每 4 秒 / 暂停 / 退出回报进度；`AppStore.saveProgress()` 过滤不足 3 秒的记录，97% 视为看完；
6. 评论 = 详情数据里的示例评论 + `AppStore` 本地评论，界面合并展示；
7. 下载由 `DownloadManager` 负责：先探测文件大小，再按 `planChunks()` 切成 4 段并发 `Range` 请求，各段写独立 `.partN` 文件，最后按顺序合并成目标文件。

## 内容形态与字段

| kind | 用到的字段 | 页面 |
| --- | --- | --- |
| article | body, tags, comments | 详情正文 |
| reading | body | ReadingPage（字号） |
| video | episodes[] / media_url | 剧集 + PlayerPage |
| audio | media_url / episodes[] | PlayerPage（无画面） |
| gallery | images[] | GalleryPage |
| comic | images[] | ComicPage |

## 下载设计

- 纯 Dart，不引入下载插件；`http` + `dart:io` 的 `RandomAccessFile` / `IOSink`；
- 探测大小：`GET Range: bytes=0-0`，从 `Content-Range` 取总长度；拿不到就退化为单连接流式下载；
- 分片：`planChunks(total, 4)`，段长尽量均匀，段数不超过字节数；
- 合并：4 个 `.partN` 文件按段顺序串行 `addStream` 进目标文件；
- 元数据：`<appSupport>/downloads/tasks.json`，启动时把「上次还在下载」的任务标记为失败，避免假进度；
- 取消：置取消标记 + 关闭 client，清理临时分片。

## 本地存储键

| 键 | 内容 |
| --- | --- |
| `settings.sourceId` / `settings.httpBaseUrl` / `settings.themeMode` | 设置 |
| `favorites.v1` | 收藏（`sourceId/itemId` 唯一） |
| `progress.v1` | 播放进度（继续观看 / 历史） |
| `comments.v1` | 本地追加的评论 |

## 扩展建议

- **按集记录进度**：把 `PlayProgress.key` 改成 `sourceId/itemId#episodeIndex`，详情页播放时传集数；
- **离线缓存**：列表 / 封面用 `path_provider` 落盘，`ContentSource` 外面套一层缓存装饰器；
- **画中画**：见 `PIP-ANDROID.md`，需要生成 android/ 后改清单与原生代码；
- **鉴权**：如果自己的后端需要登录，把 token 放 `AppStore` 或单独 `AuthStore`，在 `ContentSource` 里统一加 header。

## 已知限制（刻意留白）

- 没有缓存层：每次进页面都重新请求；
- 没有分页：列表一次全量返回；
- 下载不支持断点续传（取消后重下）；
- 评论只存本机，没有服务端；
- 主题只有一套 seed 色；
- 测试覆盖模型、进度、分片；UI 层需要 Flutter 环境才能测。
