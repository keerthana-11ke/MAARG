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
    afterEvaluate {
        val androidExtension = extensions.findByName("android")
        if (androidExtension != null) {
            try {
                // 1. Inject namespace if missing
                val getNamespaceMethod = androidExtension.javaClass.methods.firstOrNull { it.name == "getNamespace" }
                val setNamespaceMethod = androidExtension.javaClass.methods.firstOrNull { 
                    it.name == "setNamespace" && it.parameterTypes.size == 1 && it.parameterTypes[0] == String::class.java 
                }
                if (getNamespaceMethod != null && setNamespaceMethod != null) {
                    val currentNamespace = getNamespaceMethod.invoke(androidExtension)
                    if (currentNamespace == null) {
                        setNamespaceMethod.invoke(androidExtension, "com.example.maarg.plugin.${project.name.replace("-", "_").replace(".", "_")}")
                    }
                }

                // 2. Strip package attribute from AndroidManifest.xml to satisfy AGP 8+ namespace constraints
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    var contents = manifestFile.readText()
                    if (contents.contains("package=")) {
                        contents = contents.replace(Regex("""\s*package="[^"]*""""), "")
                        manifestFile.writeText(contents)
                        logger.quiet("[GradleManifestFix] Successfully removed package attribute from ${project.name}'s AndroidManifest.xml")
                    }
                }

                // 3. Align compileOptions Java version and Kotlin jvmTarget to Java 17
                val getCompileOptionsMethod = androidExtension.javaClass.methods.firstOrNull { it.name == "getCompileOptions" }
                if (getCompileOptionsMethod != null) {
                    val compileOptions = getCompileOptionsMethod.invoke(androidExtension)
                    val setSourceCompat = compileOptions.javaClass.methods.firstOrNull { it.name == "setSourceCompatibility" }
                    val setTargetCompat = compileOptions.javaClass.methods.firstOrNull { it.name == "setTargetCompatibility" }
                    if (setSourceCompat != null && setTargetCompat != null) {
                        setSourceCompat.invoke(compileOptions, org.gradle.api.JavaVersion.VERSION_17)
                        setTargetCompat.invoke(compileOptions, org.gradle.api.JavaVersion.VERSION_17)
                    }
                }

                val getKotlinOptionsMethod = androidExtension.javaClass.methods.firstOrNull { it.name == "getKotlinOptions" }
                if (getKotlinOptionsMethod != null) {
                    val kotlinOptions = getKotlinOptionsMethod.invoke(androidExtension)
                    val setJvmTarget = kotlinOptions.javaClass.methods.firstOrNull { 
                        it.name == "setJvmTarget" && it.parameterTypes.size == 1 && it.parameterTypes[0] == String::class.java 
                    }
                    if (setJvmTarget != null) {
                        setJvmTarget.invoke(kotlinOptions, "17")
                    }
                }
            } catch (e: Exception) {
                // Safe ignore
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    tasks.configureEach {
        if (this.javaClass.name.contains("KotlinCompile")) {
            try {
                val kotlinOptions = this.javaClass.getMethod("getKotlinOptions").invoke(this)
                kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java).invoke(kotlinOptions, "17")
            } catch (e: Exception) {}
        }
    }
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
