allprojects {
    repositories {
        google()
        mavenCentral()
    }
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

// Fix for old plugins not specifying a namespace, required by AGP 8+.
subprojects {
    afterEvaluate {
        val android = extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
        if (android != null && android.namespace == null) {
            val manifest = file("src/main/AndroidManifest.xml")
            if (manifest.exists()) {
                val pkg = Regex("package=\"([^\"]+)\"").find(manifest.readText())?.groupValues?.get(1)
                if (pkg != null) {
                    android.namespace = pkg
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
