param(
    [string]$Device = '192.168.1.206:5555',
    [switch]$Debug
)

. "$PSScriptRoot\arc-env.ps1"

flutter pub get
if ($Debug) {
    flutter build apk --debug
    $apk = Join-Path $RepoRoot 'build\app\outputs\flutter-apk\app-debug.apk'
} else {
    flutter build apk --release
    $apk = Join-Path $RepoRoot 'build\app\outputs\flutter-apk\app-release.apk'
}

adb connect $Device
adb install -r $apk

# Reinstalling can clear Accessibility state on Fire OS. Home Guard is the
# non-root mechanism that keeps Amazon's protected launcher from staying front.
adb shell settings put secure accessibility_enabled 1
adb shell settings put secure enabled_accessibility_services tv.opencore.launcher/tv.opencore.launcher.HomeGuardAccessibilityService
adb shell appops set tv.opencore.launcher SYSTEM_ALERT_WINDOW allow
adb shell pm grant tv.opencore.launcher android.permission.READ_LOGS
adb shell pm grant tv.opencore.launcher android.permission.WRITE_SECURE_SETTINGS
adb shell monkey -p tv.opencore.launcher -c android.intent.category.LAUNCHER 1
