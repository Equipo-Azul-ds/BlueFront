import com.android.build.gradle.LibraryExtension
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false

}


val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    plugins.withId("com.android.library") {
        if (name == "isar_flutter_libs") {
            extensions.configure<LibraryExtension> {
                namespace = "isar.flutter.libs"
            }
            // Remove deprecated package attribute from manifest to satisfy AGP 8+
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val original = manifestFile.readText()
                val updated = original.replace("""package=\"dev.isar.isar_flutter_libs\""" , "")
                if (original != updated) {
                    manifestFile.writeText(updated)
                }
            }
        }
    }
}