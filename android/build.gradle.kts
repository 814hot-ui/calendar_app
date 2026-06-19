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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// android/build.gradle.kts 파일 맨 아래에 기존 추가했던 것을 지우고 이걸로 덮어써 주세요!

subprojects.forEach { subproject ->
    subproject.plugins.whenPluginAdded {
        if (this.javaClass.name.contains("com.android.build.gradle.LibraryPlugin") || 
            this.javaClass.name.contains("com.android.build.gradle.AppPlugin")) {
            
            val androidExtension = subproject.extensions.findByName("android") as? com.android.build.api.dsl.CommonExtension<*, *, *, *, *, *>
            if (androidExtension != null && androidExtension.namespace == null) {
                // 패키지 빌드 즉시 namespace가 비어있다면 그룹명으로 강제 주입
                androidExtension.namespace = subproject.group.toString()
            }
        }
    }
}
