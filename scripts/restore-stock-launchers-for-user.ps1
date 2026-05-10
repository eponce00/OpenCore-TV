param(
    [string]$Device = '192.168.1.206:5555'
)

. "$PSScriptRoot\arc-env.ps1"

adb connect $Device
adb shell cmd package install-existing --user 0 com.amazon.tv.launcher
adb shell cmd package install-existing --user 0 com.amazon.firehomestarter
adb shell monkey -p tv.opencore.launcher -c android.intent.category.LAUNCHER 1
