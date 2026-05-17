param(
    [Parameter(Mandatory = $true)]
    [string]$Device,
    [switch]$SetHome,
    [switch]$Debug
)

. "$PSScriptRoot\arc-env.ps1"

$adbTarget = if ($Device.Contains(':')) { $Device } else { "${Device}:5555" }
$service = 'tv.opencore.launcher/tv.opencore.launcher.HomeGuardAccessibilityService'

function Enable-OpenCoreAccessibility {
    $enabled = (adb -s $adbTarget shell settings get secure enabled_accessibility_services).Trim()
    if ($enabled -eq 'null' -or [string]::IsNullOrWhiteSpace($enabled)) {
        $next = $service
    } elseif ($enabled.Split(':') -contains $service) {
        $next = $enabled
    } else {
        $next = "$enabled`:$service"
    }

    adb -s $adbTarget shell settings put secure accessibility_enabled 1
    adb -s $adbTarget shell settings put secure enabled_accessibility_services $next
}

flutter pub get
if ($Debug) {
    flutter build apk --debug
    $apk = Join-Path $RepoRoot 'build\app\outputs\flutter-apk\app-debug.apk'
} else {
    flutter build apk --release
    $apk = Join-Path $RepoRoot 'build\app\outputs\flutter-apk\app-release.apk'
}

adb connect $adbTarget
adb -s $adbTarget install -r $apk

Write-Host "Enabling OpenCore accessibility capture for learned remote buttons."
Enable-OpenCoreAccessibility

if ($SetHome) {
    Write-Host "Setting OpenCore TV as the preferred HOME activity for user 0."
    Write-Host "This does not disable or uninstall the stock launcher."
    adb -s $adbTarget shell cmd package set-home-activity --user 0 tv.opencore.launcher
}

adb -s $adbTarget shell monkey -p tv.opencore.launcher -c android.intent.category.LAUNCHER 1
