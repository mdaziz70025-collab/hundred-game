Run flutter build apk --release

Running Gradle task 'assembleRelease'...                        
Checking the license for package Android SDK Build-Tools 30.0.3 in /usr/local/lib/android/sdk/licenses
License for package Android SDK Build-Tools 30.0.3 accepted.
Preparing "Install Android SDK Build-Tools 30.0.3 (revision: 30.0.3)".
"Install Android SDK Build-Tools 30.0.3 (revision: 30.0.3)" ready.
Installing Android SDK Build-Tools 30.0.3 in /usr/local/lib/android/sdk/build-tools/30.0.3
"Install Android SDK Build-Tools 30.0.3 (revision: 30.0.3)" complete.
"Install Android SDK Build-Tools 30.0.3 (revision: 30.0.3)" finished.
Note: /home/runner/.pub-cache/hosted/pub.dev/google_mobile_ads-5.2.0/android/src/main/java/io/flutter/plugins/googlemobileads/AdMessageCodec.java uses or overrides a deprecated API.
Note: Recompile with -Xlint:deprecation for details.
lib/game_screen.dart:235:79: Error: No named parameter with the name 'italic'.
                        style: TextStyle(color: Colors.white70, fontSize: 14, italic: true),
                                                                              ^^^^^^
/opt/hostedtoolcache/flutter/stable-3.19.6-x64/flutter/packages/flutter/lib/src/painting/text_style.dart:477:9: Context: Found this candidate, but the arguments don't match.
  const TextStyle({
        ^^^^^^^^^
Target kernel_snapshot failed: Exception


FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:compileFlutterBuildRelease'.
> Process 'command '/opt/hostedtoolcache/flutter/stable-3.19.6-x64/flutter/bin/flutter'' finished with non-zero exit value 1

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.

* Get more help at https://help.gradle.org

BUILD FAILED in 1m 46s
Running Gradle task 'assembleRelease'...                          107.3s
Gradle task assembleRelease failed with exit code 1
Error: Process completed with exit code 1.
