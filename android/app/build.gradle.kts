plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.calendar_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.calendar_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    configurations.all {
        resolutionStrategy {
            force("androidx.annotation:annotation:1.8.0")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    
    // 🌟 [추가 1] 플레이버 차원 정의
    flavorDimensions.add("default")

    // 🌟 [추가 2] 구체적인 플레이버 명세 (코틀린 DSL 문법 기준)
    productFlavors {
        create("free") {
            dimension = "default"
            applicationIdSuffix = ".free"
            resValue("string", "app_name", "Biscuit Calendar (Free)")
        }
        create("pro") {
            dimension = "default"
            applicationIdSuffix = ".pro"
            resValue("string", "app_name", "Biscuit Calendar Pro")
        }
    }

    packagingOptions {
        resources {
            excludes.add("/META-INF/{AL2.0,LGPL2.1}")
        }
        jniLibs {
            pickFirsts.add("**/libsqlite3.so")
        }
    }

    // 🌟 빌드 완료 시 APK/AAB 파일명을 [앱이름-플레이버-버전.apk] 형태로 자동 변경
    applicationVariants.all {
        val variant = this
        variant.outputs.all {
            val output = this as com.android.build.gradle.internal.api.ApkVariantOutputImpl
            
            // 플레이버 이름 (free 또는 pro)
            val flavorName = variant.productFlavors[0].name 
            
            // 버전 이름 (예: 1.0.0)
            val versionName = variant.versionName 
            
            // 최종 파일명 조립 (예: BiscuitCalendar-free-1.0.0.apk)
            output.outputFileName = "BiscuitCalendar-${flavorName}-${versionName}.apk"
        }
    }
}



flutter {
    source = "../.."
}
