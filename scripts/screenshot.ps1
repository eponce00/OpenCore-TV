param(
    [string]$Device = '192.168.1.206:5555',
    [string]$Out = 'OpenCore-screen.png'
)

. "$PSScriptRoot\arc-env.ps1"

adb connect $Device
adb exec-out screencap -p > (Join-Path $RepoRoot $Out)
