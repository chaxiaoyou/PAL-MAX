# Needham Capital  ProGuard / R8 rules
#
# 引擎自身按名字加载的那几个包必须保留；注册表类也被引擎按名字查找。
# 注意不要写成 `-keep class io.flutter.** { *; }`：那条会把所有插件类一起
# 钉住，反编译 dex 就能直接看到 io.flutter.plugins.webviewflutter.* 这种名字。
# Flutter 自带的 flutter_proguard_rules.pro 对插件实现类给的是
# `-keep,allowobfuscation class <1>`，即官方允许把插件类重命名。
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# 主 Activity（清单中引用，R8 默认保留，这里显式声明更稳妥）。
-keep class com.blockmind.puzzleworld.blockquest.MainActivity { *; }

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
