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

# Google Play Services & Google Sign-In
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Suppress warnings for missing classes
-dontwarn org.checkerframework.**
-dontwarn javax.annotation.**
-dontwarn com.google.errorprone.**
-dontwarn com.google.android.play.**
