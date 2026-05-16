param(
    [string]$PromptLibrary = 'assets\wallpapers\prompt-library.json',

    [string]$Category = '',

    [ValidateSet('all', 'dark', 'clear')]
    [string]$Theme = 'all',

    [int]$LimitPerCategoryTheme = 10,

    [int]$SkipPerCategoryTheme = 0,

    [string]$Model = '',

    [switch]$DryRun,

    [int]$PollSeconds = 5,

    [int]$TimeoutMinutes = 10
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$LibraryPath = Join-Path $RepoRoot $PromptLibrary
$Generator = Join-Path $PSScriptRoot 'generate-wallpapers.ps1'

if (-not (Test-Path $LibraryPath)) {
    throw "Prompt library not found: $LibraryPath"
}

$library = Get-Content -Raw $LibraryPath | ConvertFrom-Json
$selectedModel = if ([string]::IsNullOrWhiteSpace($Model)) { $library.model } else { $Model }
$resolution = if ($library.resolution) { $library.resolution } else { '4K' }
$aspectRatio = if ($library.aspectRatio) { $library.aspectRatio } else { '16:9' }
$outputFormat = if ($library.outputFormat) { $library.outputFormat } else { 'png' }
$negative = if ($library.globalNegative) { $library.globalNegative } else { '' }
$darkDominance = if ($library.darkDominance) { $library.darkDominance } else { '' }

$categories = @($library.categories)
if (-not [string]::IsNullOrWhiteSpace($Category)) {
    $categories = @($categories | Where-Object { $_.id -eq $Category })
    if ($categories.Count -eq 0) {
        throw "No category named '$Category'."
    }
}

$themeNames = if ($Theme -eq 'all') { @('dark', 'clear') } else { @($Theme) }
$total = 0

foreach ($categoryItem in $categories) {
    foreach ($themeName in $themeNames) {
        $promptItems = @($categoryItem.themes.$themeName)
        if ($promptItems.Count -eq 0) {
            continue
        }

        $selectedPrompts = @($promptItems |
            Select-Object -Skip $SkipPerCategoryTheme -First $LimitPerCategoryTheme)
        $brightness = if ($themeName -eq 'clear') { 'light' } else { 'dark' }
        $prefix = '{0}_{1}' -f $brightness, $categoryItem.id

        foreach ($item in $selectedPrompts) {
            $tags = @($categoryItem.tags)
            if ($tags -notcontains $categoryItem.id) {
                $tags = @($categoryItem.id) + $tags
            }
            if ($tags -notcontains $item.style) {
                $tags += $item.style
            }

            $promptParts = @($item.prompt)
            if ($themeName -eq 'dark' -and -not [string]::IsNullOrWhiteSpace($darkDominance)) {
                $promptParts += $darkDominance
            }
            $promptParts += $negative
            $prompt = $promptParts -join ' '

            $generatorParams = @{
                Mode = 'Generate'
                Prompt = $prompt
                Brightness = $brightness
                Categories = $tags
                Model = $selectedModel
                Prefix = $prefix
                Resolution = $resolution
                AspectRatio = $aspectRatio
                OutputFormat = $outputFormat
                PollSeconds = $PollSeconds
                TimeoutMinutes = $TimeoutMinutes
            }

            if ($DryRun) {
                $generatorParams.DryRun = $true
            }

            Write-Host "[$themeName/$($categoryItem.id)/$($item.style)]"
            & $Generator @generatorParams
            $total++
        }
    }
}

Write-Host "Processed $total wallpaper prompts using $selectedModel."
