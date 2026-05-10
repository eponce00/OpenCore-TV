$RepoRoot = Split-Path -Parent $PSScriptRoot
$ToolRoot = 'C:\Users\ernes\Documents\Codex\2026-05-09\you-said-i-have-a-hisense\android-build-tools'

$env:JAVA_HOME = Join-Path $ToolRoot 'jdk-21'
$env:ANDROID_HOME = Join-Path $ToolRoot 'android-sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:PATH = "$(Join-Path $ToolRoot 'flutter\bin');$env:JAVA_HOME\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"

Set-Location $RepoRoot
