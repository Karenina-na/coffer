# Coffer ProGuard / R8 rules
# 当前工程核心逻辑都在 Dart 层，Android 侧仅作为插件宿主；
# 此文件为发布前最小化规则集合，避免各 flutter plugin 的反射类被裁掉。

# ------- Flutter engine & plugin registrant -------
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ------- flutter_local_notifications -------
# 插件使用 Gson 反序列化任务载荷，R8 不能混淆其 model 类。
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# ------- local_auth （生物识别） -------
-keep class io.flutter.plugins.localauth.** { *; }

# ------- flutter_secure_storage -------
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ------- SQLite3 / drift (native) -------
# sqlite3 原生库通过 FFI 访问，无反射需求，但 drift 的注解反射
# 仅发生在 dart_dev（构建时），release 运行时不需要额外 -keep。

# ------- 常规 -------
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
