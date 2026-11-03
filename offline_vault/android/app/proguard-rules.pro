# vaultOFF Proguard / R8 Rules

# Flutter & Play Store Split/Deferred Components
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.core.**

# Drift & SQLite native bindings
-keep class com.simonbinder.sqlite3.** { *; }
-dontwarn com.simonbinder.sqlite3.**

# Workmanager & Android Jetpack Work
-keep class androidx.work.** { *; }
-keep class dev.fluttercommunity.workmanager.** { *; }
-dontwarn androidx.work.**

# JNI & native libs
-keepclasseswithmembernames class * {
    native <methods>;
}
