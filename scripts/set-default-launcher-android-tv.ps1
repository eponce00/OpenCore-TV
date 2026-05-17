param(
    [Parameter(Mandatory = $true)]
    [string]$Device
)

. "$PSScriptRoot\arc-env.ps1"

$adbTarget = if ($Device.Contains(':')) { $Device } else { "${Device}:5555" }

adb connect $adbTarget

Write-Host "Setting OpenCore TV as the preferred HOME activity for user 0."
Write-Host "This does not disable or uninstall the stock launcher."
adb -s $adbTarget shell cmd package set-home-activity --user 0 tv.opencore.launcher
adb -s $adbTarget shell cmd package resolve-activity --user 0 --brief -a android.intent.action.MAIN -c android.intent.category.HOME -c android.intent.category.DEFAULT
