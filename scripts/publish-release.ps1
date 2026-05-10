param(
  [string]$Tag = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

. .\scripts\arc-env.ps1

if ([string]::IsNullOrWhiteSpace($Tag)) {
  $versionLine = Select-String -Path ".\pubspec.yaml" -Pattern "^version:\s*(.+)$" | Select-Object -First 1
  if (-not $versionLine) {
    throw "Could not find version in pubspec.yaml. Pass -Tag vX.Y.Z explicitly."
  }

  $version = $versionLine.Matches[0].Groups[1].Value.Trim().Split("+")[0]
  $Tag = "v$version"
}

if ($Tag -notmatch "^v\d+\.\d+\.\d+") {
  throw "Release tag '$Tag' should look like v1.0.4."
}

Write-Host "Building OpenCore TV $Tag..."
flutter build apk --release

$apk = Resolve-Path ".\build\app\outputs\flutter-apk\app-release.apk"
$sha = Resolve-Path ".\build\app\outputs\flutter-apk\app-release.apk.sha1"
$releaseDir = Join-Path $repoRoot "build\github-release"
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

$assetApk = Join-Path $releaseDir "opencore-tv-$Tag.apk"
$assetSha = Join-Path $releaseDir "opencore-tv-$Tag.apk.sha1"
Copy-Item -Force $apk $assetApk
Copy-Item -Force $sha $assetSha

$existingTag = git tag --list $Tag
if (-not $existingTag) {
  git tag $Tag
}

Write-Host "Pushing tag $Tag..."
git push origin $Tag

Write-Host "Publishing GitHub Release $Tag..."
gh release create $Tag `
  $assetApk `
  $assetSha `
  --title "OpenCore TV $Tag" `
  --notes "OpenCore TV release build. Install the APK on the TV, then use OpenCore Health to verify Home Guard."

Write-Host "Published OpenCore TV $Tag."
