# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }

# Dio / Retrofit
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**

# Your app models — reverse engineering पासून वाचव
-keep class com.coursemart.coursemart_app.** { *; }

# Dart/Flutter interop
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Google Play Core (Flutter deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }