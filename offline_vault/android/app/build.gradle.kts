import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.offlinevault.offline_vault"
    compileSdk = 36
    val localNdk = file("C:/Android/ndk/26.3.11579264")
    if (localNdk.exists()) {
        ndkVersion = "26.3.11579264"
    } else {
        ndkVersion = "27.0.12077973"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.offlinevault.offline_vault"
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyPasswordVal = System.getenv("KEYSTORE_KEY_PASSWORD") ?: keystoreProperties.getProperty("keyPassword")
            val storePasswordVal = System.getenv("KEYSTORE_STORE_PASSWORD") ?: keystoreProperties.getProperty("storePassword")
            val keyAliasVal = System.getenv("KEYSTORE_KEY_ALIAS") ?: keystoreProperties.getProperty("keyAlias")
            val storeFileVal = System.getenv("KEYSTORE_STORE_FILE") ?: keystoreProperties.getProperty("storeFile")

            if (keyPasswordVal != null && storePasswordVal != null && keyAliasVal != null && storeFileVal != null && file(storeFileVal).exists()) {
                keyAlias = keyAliasVal
                keyPassword = keyPasswordVal
                storeFile = file(storeFileVal)
                storePassword = storePasswordVal
            } else {
                // Fallback to project debug keystore
                val projectDebugKey = file("debug.keystore")
                if (projectDebugKey.exists()) {
                    keyAlias = "androiddebugkey"
                    keyPassword = "android"
                    storeFile = projectDebugKey
                    storePassword = "android"
                } else {
                    val debugConfig = getByName("debug")
                    keyAlias = debugConfig.keyAlias
                    keyPassword = debugConfig.keyPassword
                    storeFile = debugConfig.storeFile
                    storePassword = debugConfig.storePassword
                }
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
