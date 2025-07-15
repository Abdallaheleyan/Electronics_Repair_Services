plugins {
    id("com.android.application")
    id("kotlin-android")

    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")

    // Google services plugin for Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.electronics_repair_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Specify your unique Application ID
        applicationId = "com.example.electronics_repair_app"
        
        // Minimum and target SDK versions
        minSdk = 23
        targetSdk = flutter.targetSdkVersion

        // App versioning
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true

    }

    buildTypes {
        release {
            // You should replace this with a release keystore before publishing
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM (Bill of Materials) to manage Firebase library versions
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))

    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // Add other Firebase dependencies as needed, for example:
     implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
    
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")

    implementation("androidx.multidex:multidex:2.0.1")


}
