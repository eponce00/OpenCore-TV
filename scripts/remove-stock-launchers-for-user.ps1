param(
    [string]$Device = '192.168.1.206:5555'
)

. "$PSScriptRoot\arc-env.ps1"

adb connect $Device

# Make sure OpenCore and its guard are alive before removing user-0 launchers.
adb shell settings put secure accessibility_enabled 1
adb shell settings put secure enabled_accessibility_services tv.opencore.launcher/tv.opencore.launcher.HomeGuardAccessibilityService
adb shell monkey -p tv.opencore.launcher -c android.intent.category.LAUNCHER 1

# Reversible: these system APKs remain on /system_ext and can be restored with install-existing.
adb shell pm uninstall -k --user 0 com.amazon.tv.launcher
adb shell pm uninstall -k --user 0 com.amazon.firehomestarter
adb shell monkey -p tv.opencore.launcher -c android.intent.category.LAUNCHER 1
