allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Default build directory is used to avoid cross-drive issues between G: and C:

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val project = this
    project.plugins.configureEach {
        if (this is com.android.build.gradle.BasePlugin) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            if (android.namespace == null) {
                android.namespace = "com.aidem.app.generated.${project.name.replace("-", "_")}"
            }
        }
    }
}

// Global manifest fix for legacy plugins
subprojects {
    val project = this
    tasks.whenTaskAdded {
        if (name.contains("process") && name.contains("Manifest")) {
            doFirst {
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val content = manifestFile.readText()
                    if (content.contains("package=")) {
                        val newContent = content.replace(Regex("""\s+package="[^"]+""""), "")
                        manifestFile.writeText(newContent)
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
