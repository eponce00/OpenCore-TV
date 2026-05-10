param(
    [string]$Device = '192.168.1.206:5555'
)

. "$PSScriptRoot\arc-env.ps1"

adb connect $Device

# Keep OpenCore reachable before disabling the stock launcher.
adb shell settings put secure accessibility_enabled 1
adb shell settings put secure enabled_accessibility_services tv.opencore.launcher/tv.opencore.launcher.HomeGuardAccessibilityService
adb shell cmd package set-home-activity tv.opencore.launcher/.MainActivity
adb shell monkey -p tv.opencore.launcher -c android.intent.category.LAUNCHER 1

Write-Host "Trying to disable com.amazon.tv.launcher. Fire OS may reject this protected package."
adb shell pm disable-user --user 0 com.amazon.tv.launcher
if ($LASTEXITCODE -ne 0) {
    Write-Host "Fire OS blocked package disable. OpenCore will rely on Home Guard rescue instead."
}
adb shell cmd package set-home-activity tv.opencore.launcher/.MainActivity
adb shell monkey -p tv.opencore.launcher -c android.intent.category.LAUNCHER 1
