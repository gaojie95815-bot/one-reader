# Android 画中画（PiP）接入说明

iOS 版的播放器支持原生画中画 / AirPlay。Android 上画中画是**系统能力**，Flutter 侧需要改平台代码，所以本仓库只留出说明和骨架，不预置 android/ 目录（用 `flutter create .` 生成）。

## 1. 生成 android 平台壳

```bash
flutter create . --platforms=android
```

## 2. 改 AndroidManifest

`android/app/src/main/AndroidManifest.xml`，给 `MainActivity` 加两个属性：

```xml
<activity
    android:name=".MainActivity"
    android:supportsPictureInPicture="true"
    android:configChanges="orientation|screenSize|smallestScreenSize|screenLayout|uiMode"
    ... >
```

## 3. MainActivity 里允许进入 PiP

`android/app/src/main/kotlin/.../MainActivity.kt`：

```kotlin
package com.example.one_reader   // 改成你自己的包名

import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "one_reader/pip")
            .setMethodCallHandler { call, result ->
                if (call.method == "enter" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val params = PictureInPictureParams.Builder()
                        .setAspectRatio(Rational(16, 9))
                        .build()
                    result.success(enterPictureInPictureMode(params))
                } else {
                    result.notImplemented()
                }
            }
    }
}
```

## 4. Dart 侧调用

播放页里加一个按钮，调用 MethodChannel：

```dart
static const _pip = MethodChannel('one_reader/pip');

Future<void> enterPip() async {
  try {
    await _pip.invokeMethod<bool>('enter');
  } on PlatformException {
    // 低版本系统或未开启，忽略即可
  }
}
```

## 注意

- 进入 PiP 后系统会缩成小窗，`video_player` 默认继续播放，不需要暂停；
- Android 8.0（API 26）以下不支持 PiP，调用会失败，记得 try/catch；
- 如果想在 PiP 里显示播放控制，需要 `PictureInPictureParams.setActions(...)`，属于进阶内容；
- 这里只做「进入 PiP」的最小实现，足够练手；上架应用还需要处理音频焦点、通知栏媒体控制等。
