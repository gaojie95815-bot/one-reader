# One Reader · Flutter 练手项目

一个**开源、可跑、能装到手机上的 Flutter 内容客户端骨架**：六种内容形态、评论、下载、收藏、搜索、播放器，全部从零实现，只使用内置示例数据与自建 HTTP 源，不依赖任何第三方私有接口。

> 布局与交互对齐 iOS 版 One 客户端（首页 / 发现 / 我的 + 详情 / 影视剧集 / 看图 / 漫画 / 阅读）。面向练手：每个文件只做一件事，方便你在此基础上继续加功能。

## 为什么做这个

很多人想学客户端，一上来就被"接口从哪来"卡住。这个项目把问题拆开了：

1. **界面与数据解耦**：`ContentSource` 只有一个接口，界面不关心数据从哪来；
2. **自带离线数据**：`assets/demo/feed.json` 断网也能跑，覆盖六种形态；
3. **自带 mock 服务**：`scripts/mock_server.py` 用标准库起一个 JSON 服务，把网络、超时、错误、重试都练一遍；
4. **真实媒体**：视频用 Flutter 官方示例素材，图片用公开占位图，播放器、下载器逻辑完整。

拿到接口之前，你已经能练到 80% 的客户端基本功；拿到自己的接口（或自建后端）之后，只需要再写一个 `ContentSource` 实现。

## 功能

**六种内容形态**

| 形态 | 说明 |
| --- | --- |
| 图文 `article` | 封面 + 正文 + 标签 + 评论 |
| 阅读 `reading` | 独立阅读页，字号 14–26 可调，行高 1.8 |
| 影视 `video` | 剧集列表（分集播放）、续播、倍速、下载 |
| 电台 `audio` | 音频播放（波形占位）、进度、倍速 |
| 写真 `gallery` | 全屏左右翻页看图，双指缩放，页码 |
| 漫画 `comic` | 纵向连续阅读，单页失败提示 |

**页面结构（对齐 iOS 版）**

- **首页**：大标题 + 下拉刷新；「继续观看」横滑卡片（进度条、长按移除）；「推荐」分区 + 分类筛选
- **发现**：关键词搜索 + 分类筛选 + 网格浏览
- **我的**：收藏、观看历史、下载、设置入口，带数量
- **详情**：按形态切换主操作；剧集列表；图集预览；漫画试读；评论区；相关推荐
- **播放器**：续播、0.5x–2x 倍速、进度条、失败时外部播放器兜底
- **下载**：四连接分片下载（HTTP Range），进度、取消、删除、复制保存路径
- **观看历史**：进度条、左滑删除、一键清空

**基础设施**

- 本地状态：设置、收藏、播放进度（含「继续观看 / 看完」判定）、本地评论，全部落 shared_preferences
- 错误处理：加载中 / 失败（可重试）/ 空数据三种状态
- 单测：模型解析（六种形态、剧集、评论、图集）、播放进度判定、分片计算

## 目录结构

```
lib/
  main.dart                 # 入口：加载设置、初始化下载器
  core/
    models.dart             # 纯 Dart 模型（六种形态 / 剧集 / 评论 / 进度）
    source.dart             # ContentSource 接口
    store.dart              # 设置 + 收藏 + 进度 + 本地评论
    chunk_plan.dart         # 分片计算（纯函数，可单测）
    downloads.dart          # 多连接分片下载管理器
    theme.dart              # Material 3 主题
  sources/
    demo_source.dart        # 内置示例源（assets 离线数据）
    http_json_source.dart   # 通用 HTTP JSON 源
  ui/
    home_shell.dart         # 底部导航（首页 / 发现 / 我的）
    home_page.dart          # 首页：继续观看 + 推荐 + 分类
    discover_page.dart      # 发现：搜索 + 分类 + 网格
    profile_page.dart       # 我的
    detail_page.dart        # 详情：按形态渲染 + 评论 + 剧集 + 下载
    player_page.dart        # 视频/音频播放（续播 + 倍速）
    gallery_page.dart       # 写真看图
    reading_page.dart       # 阅读模式
    comic_page.dart         # 漫画阅读
    favorites_page.dart     # 收藏
    history_page.dart       # 观看历史
    downloads_page.dart     # 下载管理
    settings_page.dart      # 设置
assets/demo/feed.json       # 12 条示例（覆盖六种形态 + 评论 + 剧集 + 图集）
scripts/mock_server.py      # 本地 mock 内容源（仅标准库）
test/models_test.dart       # 模型 / 进度 / 分片单测
docs/                       # 架构、扩展、画中画说明
```

## 快速开始

要求：Flutter 3.24+（Dart 3.4+）。

```bash
git clone <你的仓库地址> one-reader
cd one-reader
flutter pub get

# 本仓库只含 lib/ 与配置，先生成 android/ios/web 平台壳（不会覆盖 lib/）
flutter create . --platforms=android,ios,web
flutter pub get

# 1) 先跑离线示例（不联网）
flutter run

# 2) 再跑网络链路：另开一个终端
python3 scripts/mock_server.py --port 8787

# 3) App 里：我的 → 设置 → 内容源 → 选「HTTP 通用源」，地址填：
#    Android 模拟器： http://10.0.2.2:8787
#    真机：           http://<电脑局域网 IP>:8787
#    桌面 / Chrome：  http://127.0.0.1:8787
```

跑测试：

```bash
flutter test
```

## 内容源 JSON 格式

`GET /feed`：

```json
{
  "source": "demo",
  "items": [
    {
      "id": "a1",
      "title": "标题",
      "summary": "摘要",
      "cover_url": "https://example.com/cover.jpg",
      "category": "随笔",
      "kind": "article",
      "duration": "3 分钟"
    }
  ],
  "details": {
    "a1": {
      "item": { "id": "a1", "title": "标题", "kind": "article" },
      "body": "正文……",
      "media_url": "https://example.com/video.mp4",
      "images": ["https://example.com/1.jpg"],
      "episodes": [
        { "title": "第 1 集", "media_url": "https://example.com/1.mp4", "duration": "0:07" }
      ],
      "comments": [
        { "id": "c1", "author": "小北", "content": "好看", "likes": 2 }
      ],
      "tags": ["标签"]
    }
  }
}
```

`kind` 取值：`article` / `reading` / `video` / `audio` / `gallery` / `comic`（未知值按图文处理）。
`GET /item/<id>` 返回单条详情的同样结构。

## 新增一个内容源

1. 在 `lib/sources/` 下新建类，`implements ContentSource`；
2. 实现 `id / name / description / fetchFeed() / fetchDetail()`；
3. 在 `lib/ui/home_shell.dart` 的 `_sources` 列表里加进去。

界面、收藏、播放、下载、评论全都不用改。细节见 [docs/ADD-A-SOURCE.md](docs/ADD-A-SOURCE.md)。

## 路线图

- [x] 搜索与分类筛选
- [x] 播放进度记忆（继续观看 / 观看历史）
- [x] 六种内容形态（图文 / 阅读 / 影视 / 电台 / 写真 / 漫画）
- [x] 剧集、评论、图集、漫画
- [x] 多连接分片下载
- [x] 播放器倍速
- [ ] 画中画实装（见 [docs/PIP-ANDROID.md](docs/PIP-ANDROID.md)，需要生成 android/ 后改清单与原生代码）
- [ ] 离线缓存（列表 + 封面）
- [ ] 详情页 Markdown 渲染
- [ ] 桌面 / 平板适配
- [ ] CI：`flutter analyze` + `flutter test`

## 合规说明

- 本项目只用于学习 Flutter 客户端开发，示例数据与媒体均为公开测试素材；
- **不包含、也不接受**任何抓取第三方平台私有接口、绕过付费/会员、破解加固的代码或数据；
- 如果你想接入自己的内容，请使用你拥有版权或已获授权的数据源。

## 许可证

[MIT](LICENSE)
