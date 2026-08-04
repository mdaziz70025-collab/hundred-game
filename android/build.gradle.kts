// 1. Buildscript block HAMESHA sabse upar hona chahiye
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.1")
    }
}

// 2. All projects repositories
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 3. Custom build directory logic (Flutter default setup)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// 4. Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
