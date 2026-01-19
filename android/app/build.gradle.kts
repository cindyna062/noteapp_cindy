import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 1. Tambahkan block ini untuk membaca file key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.noteapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.noteapp" // Pastikan ini sesuai ID aplikasi Anda
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 2. Definisikan konfigurasi signing di sini
    signingConfigs {
        create("release") {
            // Mengambil nilai dari key.properties dengan aman
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = if (keystoreProperties["storeFile"] != null) {
                file(keystoreProperties["storeFile"] as String)
            } else {
                null
            }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // 3. Ubah dari 'debug' menjadi 'release' yang baru dibuat di atas
            if (signingConfigs.findByName("release") != null) {
                 signingConfig = signingConfigs.getByName("release")
            }
            
            // Opsional: Untuk mengecilkan ukuran APK (minify)
            isMinifyEnabled = false 
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}