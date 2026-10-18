plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mathmvp.riazi_yar"
    compileSdk = flutter.compileSdkVersion
    // NDK فقط برای زنجیره ساخت Flutter لازم است (کد اپ native ندارد).
    // صریح پین شد تا AGP نسخه ۲۷ را دانلود نکند؛ نسخه نصب‌شده در SDK محیط: 28.2
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mathmvp.riazi_yar"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // ممیزی ۱.۰.۱ — سیاست امضا:
            // انتشار عمومی تا تهیه keystore امن BLOCKED است؛ کلید debug
            // برای نسخه انتشار استفاده نمی‌شود و هیچ keystore ساختگی
            // ساخته نمی‌شود. خروجی این build type «امضانشده» است و فقط
            // برای ممیزی/امضای بعدی توسط منتشرکننده با keystore خودش.
            // (minify/shrink را پلاگین Flutter برای release تنظیم می‌کند —
            //  دست نمی‌زنیم؛ رفتار یکسان با بیلد موفق ۱.۰.۰)
            signingConfig = null
        }
        create("internalTest") {
            // نسخه «تست داخلی» — جدا از انتشار:
            //  • امضا: کلید debug (فقط برای نصب روی دستگاه آزمایشگر؛
            //    هرگز برای انتشار عمومی استفاده نمی‌شود)
            //  • versionName پسوند "-internal-test" دارد تا در تنظیمات
            //    دستگاه از نسخه انتشار قابل تفکیک باشد
            //  • minify/shrink برای تست داخلی ضروری نیست؛ صریحاً خاموش
            //    (release طبق پیکربندی پلاگین Flutter بهینه می‌ماند)
            initWith(getByName("release"))
            matchingFallbacks += listOf("release")
            isDebuggable = false
            isMinifyEnabled = false
            isShrinkResources = false
            versionNameSuffix = "-internal-test"
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
