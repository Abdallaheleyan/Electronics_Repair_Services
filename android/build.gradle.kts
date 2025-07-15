allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Relocate build output to a custom directory
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Ensure app module is evaluated before other subprojects
subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task to delete the custom build directory
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Plugin management
plugins {
    // Add the Google Services Gradle plugin but don't apply it globally
    id("com.google.gms.google-services") version "4.4.2" apply false

    // Add other top-level plugins here as needed (e.g., Firebase Crashlytics, Performance, etc.)
}
