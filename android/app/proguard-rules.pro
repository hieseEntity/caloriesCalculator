# Flutter Engine & Plugins
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep all plugin classes explicitly to prevent R8 from obfuscating them
-keep class com.tekartik.sqflite.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }

# PaddleOCR Mobile (fast_paddle_ocr / PP-OCRv5 NCNN)
-keep class com.iweka.ocr.** { *; }
-keepclasseswithmembernames class com.iweka.ocr.** {
    native <methods>;
}

# Keep all JNI native methods across the app
-keepclasseswithmembernames class * {
    native <methods>;
}

# Google Play Core / Deferred Components suppressions
-dontwarn com.google.android.play.core.**
