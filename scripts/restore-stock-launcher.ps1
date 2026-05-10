param(
    [string]$Device = '192.168.1.206:5555'
)

. "$PSScriptRoot\arc-env.ps1"

adb connect $Device
adb shell pm enable com.amazon.tv.launcher
adb shell cmd package set-home-activity tv.opencore.launcher/.MainActivity
adb shell monkey -p tv.opencore.launcher -c android.intent.category.LAUNCHER 1
