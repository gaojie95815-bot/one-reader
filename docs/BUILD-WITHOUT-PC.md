# 不用电脑也能编译安装（GitHub Actions 云构建）

Flutter 官方只提供 Linux x86_64 的 SDK，手机（ARM64）上装不了标准 Flutter 工具链，所以**编译**这一步交给 GitHub 的免费服务器，手机上只负责下载和安装。

## 一次性配置

1. 在 GitHub 新建一个仓库（public 私有都行，public 的 Actions 完全免费）。
2. 把本项目推上去（两种方式任选）：
   - **手机浏览器 / GitHub App**：仓库首页 → Add file → Upload files → 把解压后的整个 `one-reader` 文件夹拖进去 → Commit；
   - **命令行**（任意有 git 的终端）：
     ```bash
     git branch -M main
     git remote add origin https://github.com/<你>/one-reader.git
     git push -u origin main
     ```
3. 确认仓库里有 `.github/workflows/android.yml`。有就会自动触发；没有就去 Actions 页手动点 `build-android` → Run workflow。

## 每次构建

1. 打开仓库的 **Actions** 页 → 最新的 `build-android` 运行；
2. 等 3–5 分钟，绿色的完成状态后点进去；
3. 页面底部 **Artifacts** 下载 `one-reader-debug-apk.zip`；
4. 解压得到 `app-debug.apk`，传到手机安装（需要允许「安装未知来源应用」）。

> debug 包用 Flutter 的调试签名，可以直接装、能跑；要上架/分发给别人时才需要配置自己的签名（见 Flutter 官方文档 release signing）。

## 构建里做了什么

- 生成 android 平台壳（`flutter create . --platforms=android`）；
- `flutter pub get`、`flutter analyze`、`flutter test`；
- `flutter build apk --debug`，产物 `build/app/outputs/flutter-apk/app-debug.apk`；
- 上传为 artifact，保留 30 天。

## 常见问题

- **Actions 没触发**：分支不是 `main`，或仓库没启用 Actions；到 Actions 页手动 Run workflow。
- **构建失败**：点开失败步骤看日志，常见是依赖版本或 analyze 报错；把日志贴出来即可定位。
- **安装被拦**：Android 12+ 需要在「设置 → 应用 → 特殊权限 → 安装未知应用」里给浏览器/文件管理器授权。
- **想构建 release / 分渠道**：把 `flutter build apk --debug` 改成 `--release`，并在 `android/key.properties` 配置自己的签名（仓库里不需要提交密钥）。
- **想顺便构建网页版**：加一步 `flutter build web` 并上传 `build/web`，可以部署到 GitHub Pages。
