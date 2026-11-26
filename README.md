# One Reader · Flutter 练手项目

一个**开源、可跑、能装到手机上的 Flutter 内容客户端骨架**：列表、详情、收藏、视频/音频播放、主题、可插拔内容源，从零实现，不依赖任何第三方私有接口。

> 面向练手：代码刻意写得直白，每个文件只做一件事。数据源是「内置示例 + 本地 mock 服务」，**不接入任何平台的私有 API、不内置任何付费内容**。

## 为什么做这个

很多人想学客户端，一上来就被"接口从哪来"卡住。这个项目把问题拆开了：

1. **界面与数据解耦**：`ContentSource` 只有一个接口，界面不关心数据从哪来；
2. **自带离线数据**：`assets/demo/feed.json` 断网也能跑；
3. **自带 mock 服务**：`scripts/mock_server.py` 用标准库起一个 JSON 服务，把网络、超时、错误、重试都练一遍；
4. **真实媒体**：视频用 Flutter 官方示例素材，音频用公开示例音轨，播放器逻辑完整。

拿到接口之前，你已经能练到 80% 的客户端基本功；拿到自己的接口（或自建后端）之后，只需要再写一个 `ContentSource` 实现。

## 功能

- 首页列表：封面、类型、分类、时长，下拉刷新
- 详情页：正文、标签、收藏、播放按钮
- 播放页：`video_player` 播放，进度条 / 暂停，失败时可用外部播放器打开
- 收藏：本地持久化，按「内容源 + 条目 id」区分
- 设置：切换内容源、配置 HTTP 源地址、浅色/深色/跟随系统
- 三种状态：加载中 / 失败（可重试）/ 空数据
- 单元测试：数据模型解析与序列化

## 目录结构

```
lib/
  main.dart                 # 入口：加载本地设置后启动
  core/
    models.dart             # 纯 Dart 模型（无 flutter 依赖，可单测）
    source.dart             # ContentSource 接口
    store.dart              # 设置 + 收藏（shared_preferences）
    theme.dart              # Material 3 主题
  sources/
    demo_source.dart        # 内置示例源（assets 离线数据）
    http_json_source.dart   # 通用 HTTP JSON 源
  ui/
    home_shell.dart         # 底部导航外壳
    home_page.dart          # 首页列表
    detail_page.dart        # 详情 + 收藏 + 播放入口
    player_page.dart        # 视频/音频播放
    favorites_page.dart     # 收藏
    settings_page.dart      # 设置
assets/demo/feed.json       # 示例数据（含详情与媒体地址）
scripts/mock_server.py      # 本地 mock 内容源（仅标准库）
test/models_test.dart       # 模型单测
docs/                       # 架构与扩展文档
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

# 3) App 里：设置 → 内容源 → 选「HTTP 通用源」，地址填：
#    Android 模拟器： http://10.0.2.2:8787
#    真机：           http://<电脑局域网 IP>:8787
#    桌面 / Chrome：  http://127.0.0.1:8787
# 保存后回首页刷新
```

跑测试：

```bash
flutter test
```

## 内容源 JSON 格式

`GET /feed` 返回列表 + 可选的内嵌详情：

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
      "item": { "id": "a1", "title": "标题" },
      "body": "正文……",
      "media_url": "https://example.com/video.mp4",
      "tags": ["标签"]
    }
  }
}
```

`GET /item/<id>` 返回单条详情：`{"item": {...}, "body": "...", "media_url": "...", "tags": [...]}`。

`kind` 取值：`article`（默认）/ `video` / `audio`。

## 新增一个内容源

1. 在 `lib/sources/` 下新建类，`implements ContentSource`；
2. 实现 `id / name / description / fetchFeed() / fetchDetail()`；
3. 在 `lib/ui/home_shell.dart` 的 `_sources` 列表里加进去。

界面、收藏、播放全都不用改。细节和示例代码见 [docs/ADD-A-SOURCE.md](docs/ADD-A-SOURCE.md)。

## 路线图（欢迎 PR）

- [ ] 搜索与分类筛选
- [ ] 离线缓存（列表 + 封面）
- [ ] 播放进度记忆
- [ ] 详情页 Markdown 渲染
- [ ] 桌面 / 平板适配
- [ ] CI：`flutter analyze` + `flutter test`

## 合规说明

- 本项目只用于学习 Flutter 客户端开发，示例数据与媒体均为公开测试素材；
- **不包含、也不接受**任何抓取第三方平台私有接口、绕过付费/会员、破解加固的代码或数据；
- 如果你想接入自己的内容，请使用你拥有版权或已获授权的数据源。

## 许可证

[MIT](LICENSE)
