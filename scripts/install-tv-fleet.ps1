param(
    [string[]]$Targets = @('all'),
    [string]$FleetFile = (Join-Path $PSScriptRoot '..\config\tv-fleet.local.yaml'),
    [switch]$Debug,
    [switch]$SetHomeAndroidTv,
    [switch]$List
)

. "$PSScriptRoot\arc-env.ps1"

function ConvertTo-AdbTarget {
    param([Parameter(Mandatory = $true)][string]$Device)
    if ($Device.Contains(':')) { return $Device }
    return "${Device}:5555"
}

function ConvertFrom-OpenCoreFleetYaml {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (!(Test-Path $Path)) {
        throw "Fleet file not found: $Path. Copy config/tv-fleet.example.yaml to config/tv-fleet.local.yaml first."
    }

    $items = @()
    $current = $null

    foreach ($rawLine in Get-Content $Path) {
        $line = $rawLine.Trim()
        if ($line.Length -eq 0 -or $line.StartsWith('#') -or $line -eq 'tvs:') {
            continue
        }

        if ($line.StartsWith('- ')) {
            if ($null -ne $current) { $items += [pscustomobject]$current }
            $current = @{}
            $line = $line.Substring(2).Trim()
            if ($line.Length -eq 0) { continue }
        }

        $parts = $line -split ':', 2
        if ($parts.Count -ne 2 -or $null -eq $current) { continue }

        $key = $parts[0].Trim()
        $value = $parts[1].Trim().Trim('"').Trim("'")
        if ($value -eq 'true') {
            $current[$key] = $true
        } elseif ($value -eq 'false') {
            $current[$key] = $false
        } else {
            $current[$key] = $value
        }
    }

    if ($null -ne $current) { $items += [pscustomobject]$current }
    return $items
}

function Test-AdbDeviceReady {
    param([Parameter(Mandatory = $true)][string]$AdbTarget)

    $state = (adb -s $AdbTarget get-state 2>$null)
    if ($LASTEXITCODE -ne 0 -or $state -ne 'device') {
        return $false
    }
    return $true
}

function Enable-OpenCoreAccessibility {
    param([Parameter(Mandatory = $true)][string]$AdbTarget)

    $service = 'tv.opencore.launcher/tv.opencore.launcher.HomeGuardAccessibilityService'
    $enabled = (adb -s $AdbTarget shell settings get secure enabled_accessibility_services).Trim()
    if ($enabled -eq 'null' -or [string]::IsNullOrWhiteSpace($enabled)) {
        $next = $service
    } elseif ($enabled.Split(':') -contains $service) {
        $next = $enabled
    } else {
        $next = "$enabled`:$service"
    }

    adb -s $AdbTarget shell settings put secure accessibility_enabled 1
    adb -s $AdbTarget shell settings put secure enabled_accessibility_services $next
}

$fleet = ConvertFrom-OpenCoreFleetYaml -Path $FleetFile
if ($List) {
    $fleet | Select-Object id, name, device, profile, setHome | Format-Table -AutoSize
    exit 0
}

if ($Targets.Count -eq 1 -and $Targets[0] -eq 'all') {
    $selected = $fleet
} else {
    $selected = $fleet | Where-Object { $Targets -contains $_.id -or $Targets -contains $_.name }
}

if (!$selected -or $selected.Count -eq 0) {
    $knownTargets = ($fleet | ForEach-Object { $_.id }) -join ', '
    throw "No matching TVs found. Known targets: $knownTargets"
}

flutter pub get
if ($Debug) {
    flutter build apk --debug
    $apk = Join-Path $RepoRoot 'build\app\outputs\flutter-apk\app-debug.apk'
} else {
    flutter build apk --release
    $apk = Join-Path $RepoRoot 'build\app\outputs\flutter-apk\app-release.apk'
}

foreach ($tv in $selected) {
    $adbTarget = ConvertTo-AdbTarget -Device $tv.device
    Write-Host ""
    Write-Host "Installing OpenCore TV on $($tv.name) [$($tv.id)] at $adbTarget ($($tv.profile))"

    adb connect $adbTarget
    if (!(Test-AdbDeviceReady -AdbTarget $adbTarget)) {
        Write-Warning "Skipping $($tv.name): ADB target is not authorized/online. Check the TV's ADB approval prompt or network connection."
        continue
    }

    adb -s $adbTarget install -r $apk

    if ($tv.profile -eq 'fireTv') {
        Write-Host "Restoring Fire TV Home Guard development grants."
        Enable-OpenCoreAccessibility -AdbTarget $adbTarget
        adb -s $adbTarget shell appops set tv.opencore.launcher SYSTEM_ALERT_WINDOW allow
        adb -s $adbTarget shell pm grant tv.opencore.launcher android.permission.READ_LOGS
        adb -s $adbTarget shell pm grant tv.opencore.launcher android.permission.WRITE_SECURE_SETTINGS
    } else {
        Write-Host "Enabling OpenCore accessibility capture for learned remote buttons."
        Enable-OpenCoreAccessibility -AdbTarget $adbTarget
    }

    if ($tv.profile -ne 'fireTv' -and ($SetHomeAndroidTv -or $tv.setHome)) {
        Write-Host "Setting OpenCore TV as preferred HOME for user 0 without disabling the stock launcher."
        adb -s $adbTarget shell cmd package set-home-activity --user 0 tv.opencore.launcher
    }

    adb -s $adbTarget shell monkey -p tv.opencore.launcher -c android.intent.category.LAUNCHER 1
}
