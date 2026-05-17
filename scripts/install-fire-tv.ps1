param(
    [string]$Device = '192.168.1.206:5555',
    [switch]$Debug
)

& "$PSScriptRoot\dev-install.ps1" -Device $Device -Debug:$Debug
