import java.util.Properties
import java.io.StringReader
import java.nio.charset.CodingErrorAction
import java.nio.ByteBuffer

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Private, ignored file. Release tasks must never produce unsigned artifacts.
val signingPropertiesFile = rootProject.file("key.properties")
val signingProperties = Properties()
if (signingPropertiesFile.exists()) {
    // Properties.load(InputStream) assumes ISO-8859-1, corrupting UTF-8 values.
    // Decode explicitly, reject malformed text and allow an editor's UTF-8 BOM.
    // Preserve all password whitespace and normal Java properties escaping.
    val decoder = Charsets.UTF_8.newDecoder()
        .onMalformedInput(CodingErrorAction.REPORT)
        .onUnmappableCharacter(CodingErrorAction.REPORT)
    val signingText = decoder.decode(
        ByteBuffer.wrap(signingPropertiesFile.readBytes())
    ).toString().removePrefix("\uFEFF")
    StringReader(signingText).use { signingProperties.load(it) }
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword").forEach { key ->
        require(!signingProperties.getProperty(key).isNullOrBlank()) {
            "Missing release signing property: $key"
        }
    }
    require(rootProject.file(signingProperties.getProperty("storeFile")).isFile) {
        "Release keystore file does not exist. Check android/key.properties."
    }
}

gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any {
        it.project == project && it.name.contains("release", ignoreCase = true)
    }
    if (buildsRelease) {
        require(signingPropertiesFile.exists()) {
            "Release signing is required. Configure private android/key.properties " +
                "and the upload keystore; see docs/GOOGLE_PLAY_RELEASE.md."
        }
    }
}

android {
    namespace = "com.allflag.allflag"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent package identity approved by the owner. Do not change.
        applicationId = "com.allflag.allflag"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (signingPropertiesFile.exists()) {
            create("release") {
                storeFile = rootProject.file(signingProperties.getProperty("storeFile"))
                storePassword = signingProperties.getProperty("storePassword")
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
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
