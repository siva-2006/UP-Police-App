plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.eclub_app" // <--- CORRECTED: Use '=' for assignment and double quotes
    compileSdk = flutter.compileSdkVersion // <--- CORRECTED: Use '=' for assignment
    ndkVersion = "27.0.12077973" // <--- CORRECTED: Use '=' for assignment and double quotes

    compileOptions {
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.eclub_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ext.set("tfliteFlutterOptions", mapOf(
            "buildFlavors" to listOf(
                "tflite_flutter_plus" // Or another custom name
            ),
            "nativeLibs" to mapOf(
                "tflite_flutter_plus" to mapOf(
                    "tflite" to "org.tensorflow:tensorflow-lite:2.14.0",
                    "tflite_gpu" to "org.tensorflow:tensorflow-lite-gpu:2.14.0",
                    // This is the key line that includes all TensorFlow ops
                    "tflite_flex" to "org.tensorflow:tensorflow-lite-select-tf-ops:2.14.0"
                )
            )
        ))

    }

    buildTypes {
        release {
             getByName("release") {
                isMinifyEnabled = false
                isShrinkResources = false
            }
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
    implementation(files("libs/jlibrosa-1.1.8-SNAPSHOT-jar-with-dependencies.jar"))
    implementation("org.tensorflow:tensorflow-lite-select-tf-ops:2.16.1")
    //implementation("com.google.ai.edge.litert:litert:1.0.1")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}