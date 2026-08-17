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

    tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
        options.isFork = true
        val javacExecutable =
            if (System.getProperty("os.name").startsWith("Windows", ignoreCase = true)) {
                "javac.exe"
            } else {
                "javac"
            }
        options.forkOptions.executable =
            file("${System.getProperty("java.home")}/bin/$javacExecutable").absolutePath
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
