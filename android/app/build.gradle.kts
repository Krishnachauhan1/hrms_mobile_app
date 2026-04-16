import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = File(rootDir, "key.properties") // ✅ Fixed path

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    throw GradleException("key.properties file not found at: ${keystorePropertiesFile.absolutePath}")
}

android {
   namespace = "com.hrms_employee_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.hrms_employee_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // ✅ Use getProperty() instead of casting
            val keyAliasValue = keystoreProperties.getProperty("keyAlias")
            val keyPasswordValue = keystoreProperties.getProperty("keyPassword")
            val storeFileValue = keystoreProperties.getProperty("storeFile")
            val storePasswordValue = keystoreProperties.getProperty("storePassword")

            if (keyAliasValue == null || keyPasswordValue == null ||
                storeFileValue == null || storePasswordValue == null) {
                throw GradleException(
                    "Missing key.properties values. Found: alias=$keyAliasValue, storeFile=$storeFileValue"
                )
            }

            keyAlias = keyAliasValue
            keyPassword = keyPasswordValue
            storeFile = file(storeFileValue)
            storePassword = storePasswordValue
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}