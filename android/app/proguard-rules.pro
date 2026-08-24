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
