# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Prevent optimization of ML Kit classes
-keepnames class com.google.mlkit.** { *; }
-keepnames class com.google.android.gms.** { *; }

# Keep specific models if needed (generic catch-all above should cover it)
