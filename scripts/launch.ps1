param(
    [string]$Device = '192.168.1.206:5555',
    [string]$Package = 'tv.opencore.launcher'
)

. "$PSScriptRoot\arc-env.ps1"

$adbTarget = if ($Device.Contains(':')) { $Device } else { "${Device}:5555" }

adb connect $adbTarget
adb -s $adbTarget shell monkey -p $Package -c android.intent.category.LAUNCHER 1
