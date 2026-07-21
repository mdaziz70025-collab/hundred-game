include ':app'

def localPropertiesFile = new File(rootProject.projectDir, "local.properties")
def properties = new Properties()

if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        properties.load(reader)
    }
}

def flutterSdkPath = properties.getProperty("flutter.sdk")
if (flutterSdkPath == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

pluginManagement {
    def flutterSdkPathCode = {
        def localProperties = new Properties()
        def file = new File(rootDir, "local.properties")
        if (file.exists()) {
            file.withReader('UTF-8') { reader ->
                localProperties.load(reader)
            }
        }
        return localProperties.getProperty("flutter.sdk")
    }
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
