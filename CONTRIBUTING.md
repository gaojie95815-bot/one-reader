# 参与贡献

谢谢愿意一起把这个练手项目做完。

## 开发流程

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## 提交前

- `flutter analyze` 无 error；
- `flutter test` 全绿；
- 新增页面/数据源时，同步更新 `README.md` 或 `docs/`。

## 内容源贡献

- 只接受**你有权使用**的数据源（自有后端、公开授权 API、自建 mock）；
- 不接受抓取第三方平台私有接口、绕过付费/会员、破解加固类的代码或数据；
- 新数据源请附一个不联网的单元测试。

## 代码风格

- 一个文件一个职责；页面自管加载状态，全局状态放 `AppStore`；
- 错误往上抛，由 UI 决定怎么显示；
- 注释写「为什么」，不写「是什么」。
