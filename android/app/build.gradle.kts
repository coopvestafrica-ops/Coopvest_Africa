plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") version "1.9.22"
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

repositories {
    google()
    mavenCentral()
}

android {
    namespace = "com.coopvestafrica.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.coopvestafrica.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Kotlin stdlib is automatically included by kotlin-gradle-plugin 2.1.0
    // Import the BoM for the Firebase platform
    implementation(platform("com.google.firebase:firebase-bom:32.5.0"))

    // Add the dependencies for Firebase products without specifying versions
    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics-ktx:21.5.0")
    // Firebase Auth
    implementation("com.google.firebase:firebase-auth-ktx:22.2.0")
    // Firebase Firestore
    implementation("com.google.firebase:firebase-firestore-ktx:24.9.1")
    // Firebase Storage
    implementation("com.google.firebase:firebase-storage-ktx:20.3.0")
    // Firebase Cloud Messaging
    implementation("com.google.firebase:firebase-messaging-ktx:23.3.1")
    // Firebase Crashlytics
    implementation("com.google.firebase:firebase-crashlytics-ktx:18.5.1")
}
