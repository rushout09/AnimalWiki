import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing key: ~/.animalwiki-signing/key.properties first, android/key.properties as a
// fallback. Neither is tracked in git. A release build with no key found must fail loudly
// instead of silently falling back to the debug key or a placeholder password.
val signingPropsFile = listOf(
    File(System.getProperty("user.home"), ".animalwiki-signing/key.properties"),
    rootProject.file("key.properties"),
).firstOrNull { it.exists() }

val requestedRelease = gradle.startParameter.taskNames.any { it.contains("Release") }
if (requestedRelease && signingPropsFile == null) {
    throw GradleException(
        "No release signing key found. Expected ~/.animalwiki-signing/key.properties " +
            "or android/key.properties. Refusing to build an unsigned or debug-signed release."
    )
}

val signingProps = Properties().apply {
    signingPropsFile?.inputStream()?.use { load(it) }
}

android {
    namespace = "info.animalidentifier"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "info.animalidentifier"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        signingPropsFile?.let {
            create("release") {
                storeFile = file(signingProps.getProperty("storeFile"))
                storePassword = signingProps.getProperty("storePassword")
                keyAlias = signingProps.getProperty("keyAlias")
                keyPassword = signingProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
