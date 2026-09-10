import com.android.build.api.dsl.ApplicationExtension

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

configure<ApplicationExtension> {
    namespace = "ug.tweyonje.tweyonje"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ug.tweyonje.tweyonje"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Google Maps API key (com.google.android.geo.API_KEY). Provide via the
        // MAPS_API_KEY environment variable or the maps_api_key_gradle.properties
        // file; the manifest won't include a key if it is unset.
        val mapsApiKey: String = (System.getenv("MAPS_API_KEY") ?: "")
            .ifEmpty { readMapsApiKeyFromProperties(file("..").resolve("maps_api_key_gradle.properties")) }
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

fun readMapsApiKeyFromProperties(propsFile: File): String {
    if (!propsFile.exists()) return ""
    return propsFile
        .readLines()
        .firstOrNull { it.trimStart().startsWith("MAPS_API_KEY=") }
        ?.substringAfter("=")
        ?.trim()
        ?.trim('"', '\'')
        .orEmpty()
}

flutter {
    source = "../.."
}