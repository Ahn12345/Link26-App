allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 한글 등 비ASCII 경로에서 aapt/zip이 APK 경로를 열지 못하는 경우가 있습니다.
// 해결: 프로젝트를 ASCII만 있는 경로로 옮기거나, tool/run_with_ascii_path.ps1 로 flutter 실행.
val link26ProjectRoot = rootProject.projectDir.parentFile!!.absolutePath
if (link26ProjectRoot.any { it > '\u007f' }) {
    logger.warn(
        """
        |Link26: 프로젝트 경로에 비ASCII 문자가 포함되어 있습니다.
        |  Android 디버그 실행 시 'Illegal byte sequence' / manifest 추출 실패가 날 수 있습니다.
        |  PowerShell:  .\tool\run_with_ascii_path.ps1 run
        |  또는 폴더를 예: C:\dev\Link26-App 처럼 옮긴 뒤 flutter clean 을 실행하세요.
        """.trimMargin(),
    )
}

rootProject.layout.buildDirectory.set(file("../build"))
subprojects {
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
