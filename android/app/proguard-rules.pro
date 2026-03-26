# Flutter & Firebase ProGuard Rules

# Keep Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Firestore
-keep class com.google.cloud.firestore.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Suppress warnings for missing classes
-dontwarn org.checkerframework.**
-dontwarn javax.annotation.**
-dontwarn com.google.errorprone.**
-dontwarn com.google.android.play.**
