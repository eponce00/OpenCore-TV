param(
    [string]$Device = '192.168.1.206:5555'
)

. "$PSScriptRoot\arc-env.ps1"

adb connect $Device

adb shell settings put secure accessibility_enabled 1
adb shell settings put secure enabled_accessibility_services tv.opencore.launcher/tv.opencore.launcher.HomeGuardAccessibilityService
adb shell appops set tv.opencore.launcher SYSTEM_ALERT_WINDOW allow
adb shell pm grant tv.opencore.launcher android.permission.READ_LOGS
adb shell pm grant tv.opencore.launcher android.permission.WRITE_SECURE_SETTINGS
adb shell monkey -p tv.opencore.launcher -c android.intent.category.LAUNCHER 1

Write-Host "OpenCore Home Guard enabled and OpenCore launched."
