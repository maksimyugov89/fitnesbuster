import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Release-подпись берётся из android/key.properties, если он есть (создаётся
// вручную для локальной release-сборки либо release.yml в CI из GitHub Secrets).
// Если файла нет — release buildType откатывается на debug-подпись, чтобы
// обычные сборки (локальные, PR, build.yml) не ломались без секретов.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.fitnesbuster.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.fitnesbuster.app"
        minSdk = 26
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.14.1"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")

    // Health Connect
    implementation("androidx.health.connect:connect-client:1.1.0")
}

flutter {
    source = "../.."
}

// Flutter 3.38.5 can generate Android GeneratedPluginRegistrant with the
// dev-only integration_test plugin even though the release classpath correctly
// excludes dev dependencies. Keep the test plugin out of production builds and
// patch only the generated registrant before release Java compilation.
val stripIntegrationTestFromReleaseRegistrant by tasks.registering {
    val registrant = layout.projectDirectory.file(
        "src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java",
    )
    inputs.file(registrant).optional()
    outputs.upToDateWhen { false }
    mustRunAfter("compileFlutterBuildRelease")

    doLast {
        val file = registrant.asFile
        if (!file.exists()) return@doLast

        val text = file.readText()
        val integrationTestBlock = Regex(
            """

\s*try \{
\s*flutterEngine\.getPlugins\(\)\.add\(new dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin\(\)\);
\s*\} catch \(Exception e\) \{
\s*Log\.e\(TAG, "Error registering plugin integration_test, dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin", e\);
\s*\}
            """.trimIndent(),
        )
        val updated = text.replace(integrationTestBlock, "")
        if (updated != text) {
            file.writeText(updated)
        }
    }
}

tasks.configureEach {
    if (name == "compileReleaseJavaWithJavac" || name == "compileReleaseKotlin") {
        dependsOn(stripIntegrationTestFromReleaseRegistrant)
    }
}
