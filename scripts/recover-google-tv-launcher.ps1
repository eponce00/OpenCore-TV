param(
    [Parameter(Mandatory = $true)]
    [string]$Device
)

. "$PSScriptRoot\arc-env.ps1"

$adbTarget = if ($Device.Contains(':')) { $Device } else { "${Device}:5555" }

adb connect $adbTarget

Write-Host "Re-enabling known Google TV stock launcher packages for user 0."
adb -s $adbTarget shell pm enable --user 0 com.google.android.apps.tv.launcherx
adb -s $adbTarget shell pm enable --user 0 com.google.android.tungsten.setupwraith
adb -s $adbTarget shell input keyevent HOME
