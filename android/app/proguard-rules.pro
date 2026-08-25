# PAL MAX ProGuard / R8 rules
#
# Flutter 引擎在运行时通过反射加载插件与注册表，R8 混淆会把这些类重命名
# 导致启动崩溃，因此保留整个 io.flutter 包及其生成的插件注册类。
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# 主 Activity（清单中引用，R8 默认保留，这里显式声明更稳妥）。
-keep class com.example.pal_max.MainActivity { *; }

# 插件与第三方库可能依赖的注解/签名元数据。
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Flutter 引擎引用了 Google Play Core 的可选类（Play 动态分发 / deferred
# components）。本项目不依赖 com.google.android.play:core，R8 开启时会因
# 缺失类报错，这里按 AGP 生成的 missing_rules.txt 添加 -dontwarn 忽略。
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
