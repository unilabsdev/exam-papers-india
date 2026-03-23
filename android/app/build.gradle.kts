import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    namespace = "com.exampapersindia.exam_papers_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "com.exampapersindia.exam_papers_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

// Auto-rename AAB to include version name and code
android.applicationVariants.configureEach {
    if (buildType.name == "release") {
        val variant = this
        tasks.named("bundle${variant.name.replaceFirstChar { it.uppercase() }}") {
            doLast {
                val outDir = layout.buildDirectory.dir("outputs/bundle/${variant.name}").get().asFile
                val oldFile = outDir.listFiles()?.firstOrNull { it.name.endsWith(".aab") } ?: return@doLast
                val newName = "ExamPapersIndia-v${variant.versionName}-vc${variant.versionCode}-release.aab"
                oldFile.renameTo(File(outDir, newName))
            }
        }
    }
}
