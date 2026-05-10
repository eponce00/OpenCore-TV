param(
    [string]$Device = '192.168.1.206:5555'
)

. "$PSScriptRoot\arc-env.ps1"

adb connect $Device
adb shell monkey -p tv.opencore.launcher.debug -c android.intent.category.LAUNCHER 1
