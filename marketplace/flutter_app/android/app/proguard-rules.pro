# Flutter specific ProGuard rules for production builds

# Keep Flutter framework classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Marketplace app specific classes
-keep class com.marketplace.** { *; }
-keep class com.example.marketplace_app.** { *; }

# Keep JSON serialization classes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep classes with @SerializedName annotations
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Gson classes
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep classes that are referenced in AndroidManifest.xml
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Keep custom View classes
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep Parcelable classes
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Firebase specific rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Stripe payment processing
-keep class com.stripe.** { *; }
-dontwarn com.stripe.**

# OkHttp and Retrofit
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn retrofit2.**

# Camera and image processing
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# WebView related
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String);
}

# Remove logging in production
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
    public static int println(...);
}

# Remove debug prints
-assumenosideeffects class java.io.PrintStream {
    public void println(%);
    public void print(%);
}

# Optimize enums
-optimizations !code/simplification/enum,!field/*,!class/merging/*

# Performance optimizations
-allowaccessmodification
-repackageclasses ''
-optimizationpasses 5

# Keep crash reporting
-keep class org.chromium.** { *; }
-keep class com.crashlytics.** { *; }
-dontwarn com.crashlytics.**

# Keep analytics
-keep class com.google.analytics.** { *; }
-dontwarn com.google.analytics.**

# Local authentication
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# Networking libraries
-keep class com.squareup.** { *; }
-dontwarn com.squareup.**

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep BuildConfig
-keep class **.BuildConfig { *; }

# Prevent obfuscation of classes with custom constructors used by dependency injection
-keepclassmembers class * {
    @javax.inject.* *;
    @dagger.* *;
}

# Additional Firebase rules
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

# Keep notification classes
-keep class androidx.core.app.NotificationCompat* { *; }

# Accessibility services
-keep class androidx.core.view.accessibility.** { *; }

# Keep fragment classes
-keep public class * extends androidx.fragment.app.Fragment

# Keep lifecycle classes
-keep class androidx.lifecycle.** { *; }