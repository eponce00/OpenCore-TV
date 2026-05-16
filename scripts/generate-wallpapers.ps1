param(
    [ValidateSet('Generate', 'List4kModels', 'SearchModels')]
    [string]$Mode = 'Generate',

    [string]$Search = '',

    [string]$Prompt,

    [ValidateSet('dark', 'light')]
    [string]$Brightness = 'dark',

    [string[]]$Categories = @('art'),

    [string]$Model = 'fal-ai/nano-banana-2',

    [string]$Prefix,

    [int]$Count = 1,

    [string]$Resolution = '4K',

    [string]$AspectRatio = '16:9',

    [string]$OutputFormat = 'png',

    [string]$ExtraInputJson = '{}',

    [switch]$DryRun,

    [int]$PollSeconds = 5,

    [int]$TimeoutMinutes = 10
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$CatalogPath = Join-Path $RepoRoot 'assets\wallpapers\catalog.json'
$RequestLogPath = Join-Path $RepoRoot 'assets\wallpapers\fal-requests.jsonl'
$FalModelsUrl = 'https://fal.ai/api/models'
$FalQueueRoot = 'https://queue.fal.run'

function Get-FalHeaders {
    if ([string]::IsNullOrWhiteSpace($env:FAL_KEY)) {
        return @{}
    }

    return @{ Authorization = "Key $env:FAL_KEY" }
}

function Get-FalTextToImageModels {
    $headers = Get-FalHeaders
    $pageSize = 100
    $first = Invoke-RestMethod -Headers $headers -Uri "$FalModelsUrl`?size=$pageSize&page=1" -Method Get
    $items = @($first.items)

    for ($page = 2; $page -le [int]$first.pages; $page++) {
        $response = Invoke-RestMethod -Headers $headers -Uri "$FalModelsUrl`?size=$pageSize&page=$page" -Method Get
        $items += @($response.items)
    }

    return $items | Where-Object {
        $_.category -eq 'text-to-image' -and
        -not $_.deprecated -and
        -not $_.removed
    }
}

function Show-4kModels {
    $models = Get-FalTextToImageModels
    $candidatePattern = '(?i)4k|4 k|4096|openai/gpt-image-2|gpt-image-1\.5|nano-banana-(2|pro)|gemini-3|flux-2-max|imagen4/preview/ultra|kling-image/o3|phota|qwen-image-2/pro|seedream/v5|recraft/v4\.1/pro'
    $matches = $models | Where-Object {
        $haystack = @(
            $_.id
            $_.pricingInfoOverride
            $_.billingMessage
            $_.shortDescription
            ($_.tags -join ' ')
        ) -join ' '

        $haystack -match $candidatePattern
    } | Sort-Object id

    $matches | Select-Object `
        id,
        title,
        modelLab,
        modelFamily,
        @{ Name = 'resolutionEvidence'; Expression = {
            $haystack = @($_.pricingInfoOverride, $_.billingMessage, $_.shortDescription, ($_.tags -join ' ')) -join ' '
            if ($haystack -match '(?i)4k|4 k|4096') {
                'API text mentions 4K/4096'
            } elseif ($_.id -match 'openai/gpt-image-2') {
                'candidate: GPT Image 2, token-priced; listing omits 4K text'
            } elseif ($_.id -match 'flux-2-max|imagen4/preview/ultra|qwen-image-2/pro|seedream/v5|recraft/v4\.1/pro') {
                'candidate: high-end/high-resolution family; verify endpoint params'
            } else {
                'candidate'
            }
        }},
        @{ Name = 'pricing'; Expression = {
            if ($_.pricingInfoOverride) {
                ($_.pricingInfoOverride -replace '\*\*', '' -replace '\s+', ' ').Trim()
            } elseif ($_.billingMessage) {
                ($_.billingMessage -replace '\s+', ' ').Trim()
            } else {
                'No explicit price in model listing'
            }
        }} | Format-Table -Wrap
}

function Search-Models {
    $models = Get-FalTextToImageModels
    if (-not [string]::IsNullOrWhiteSpace($Search)) {
        $terms = [regex]::Escape($Search) -replace '\\ ', '|'
        $models = $models | Where-Object {
            (@($_.id, $_.title, $_.modelLab, $_.modelFamily, $_.shortDescription, ($_.tags -join ' ')) -join ' ') -match "(?i)$terms"
        }
    }

    $models | Sort-Object id | Select-Object `
        id,
        title,
        modelLab,
        modelFamily,
        @{ Name = 'pricing'; Expression = {
            if ($_.pricingInfoOverride) {
                ($_.pricingInfoOverride -replace '\*\*', '' -replace '\s+', ' ').Trim()
            } elseif ($_.billingMessage) {
                ($_.billingMessage -replace '\s+', ' ').Trim()
            } else {
                'No explicit price in model listing'
            }
        }},
        shortDescription | Format-Table -Wrap
}

function ConvertFrom-JsonObject {
    param([string]$Json)

    if ([string]::IsNullOrWhiteSpace($Json)) {
        return @{}
    }

    $parsed = $Json | ConvertFrom-Json -AsHashtable
    if ($null -eq $parsed) {
        return @{}
    }

    return $parsed
}

function Get-ModelPayload {
    param(
        [string]$ModelId,
        [string]$ImagePrompt,
        [string]$Size,
        [string]$Ratio,
        [string]$Format,
        [hashtable]$Extra
    )

    $payload = @{
        prompt = $ImagePrompt
        num_images = 1
        aspect_ratio = $Ratio
        output_format = $Format
    }

    if ($ModelId -match 'openai/gpt-image-2|gpt-image-1\.5|gpt-image-1') {
        $payload.size = '4096x2304'
        $payload.quality = 'high'
    } elseif ($ModelId -match 'nano-banana|gemini-3|kling-image|phota') {
        $payload.resolution = $Size
    } elseif ($ModelId -match 'seedream') {
        $payload.size = $Size
    } elseif ($ModelId -match 'flux-pro/v1\.1-ultra') {
        $payload.image_size = 'landscape_16_9'
    } else {
        $payload.resolution = $Size
    }

    foreach ($key in $Extra.Keys) {
        $payload[$key] = $Extra[$key]
    }

    return $payload
}

function Get-NextWallpaperName {
    param(
        [array]$Catalog,
        [string]$NamePrefix,
        [string]$Extension
    )

    $existingIds = @($Catalog | ForEach-Object { $_.id })
    $index = 1
    do {
        $id = '{0}_{1:d2}' -f $NamePrefix, $index
        $index++
    } while ($existingIds -contains $id)

    return @{
        id = $id
        file = "$id.$Extension"
    }
}

function Find-ImageUrls {
    param($Value)

    $urls = New-Object System.Collections.Generic.List[string]

    function Visit {
        param($Node)

        if ($null -eq $Node) {
            return
        }

        if ($Node -is [string]) {
            if ($Node -match '^https?://' -and ($Node -match '(?i)\.(png|jpg|jpeg|webp)(\?|$)' -or $Node -match 'fal\.media')) {
                $urls.Add($Node)
            }
            return
        }

        if ($Node -is [System.Collections.IDictionary]) {
            foreach ($key in $Node.Keys) {
                Visit $Node[$key]
            }
            return
        }

        if ($Node -is [System.Collections.IEnumerable] -and -not ($Node -is [string])) {
            foreach ($item in $Node) {
                Visit $item
            }
            return
        }

        $Node.PSObject.Properties | ForEach-Object { Visit $_.Value }
    }

    Visit $Value
    return @($urls | Select-Object -Unique)
}

function Invoke-FalGeneration {
    param([hashtable]$Payload)

    $uri = "$FalQueueRoot/$Model"
    $body = $Payload | ConvertTo-Json -Depth 20

    if ($DryRun) {
        Write-Host "Dry run: would POST to $uri"
        Write-Host $body
        return $null
    }

    if ([string]::IsNullOrWhiteSpace($env:FAL_KEY)) {
        throw 'Set FAL_KEY in the environment before generating images.'
    }

    $headers = Get-FalHeaders
    $queued = Invoke-RestMethod -Headers $headers -Uri $uri -Method Post -ContentType 'application/json' -Body $body
    [pscustomobject]@{
        timestamp = (Get-Date).ToString('o')
        model = $Model
        request_id = $queued.request_id
        status_url = $queued.status_url
        response_url = $queued.response_url
        prompt = $Payload.prompt
    } | ConvertTo-Json -Compress -Depth 8 | Add-Content -Encoding UTF8 $RequestLogPath
    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)

    while ((Get-Date) -lt $deadline) {
        $status = Invoke-RestMethod -Headers $headers -Uri $queued.status_url -Method Get
        if ($status.status -eq 'COMPLETED') {
            return Invoke-RestMethod -Headers $headers -Uri $queued.response_url -Method Get
        }

        if ($status.status -eq 'FAILED') {
            throw "fal request failed: $($status | ConvertTo-Json -Depth 8)"
        }

        Write-Host "fal status: $($status.status)"
        Start-Sleep -Seconds $PollSeconds
    }

    throw "Timed out waiting for fal request after $TimeoutMinutes minutes."
}

function Add-WallpaperToCatalog {
    param(
        [string]$Id,
        [string]$AssetPath
    )

    $catalog = @()
    if (Test-Path $CatalogPath) {
        $catalog = @(Get-Content -Raw $CatalogPath | ConvertFrom-Json)
    }

    $entry = [ordered]@{
        id = $Id
        asset = $AssetPath
        brightness = $Brightness
        categories = @($Categories)
    }

    $catalog += [pscustomobject]$entry
    $catalog | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $CatalogPath
}

if ($Mode -eq 'List4kModels') {
    Show-4kModels
    exit 0
}

if ($Mode -eq 'SearchModels') {
    Search-Models
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Prompt)) {
    throw 'Pass -Prompt for Generate mode.'
}

$catalog = @()
if (Test-Path $CatalogPath) {
    $catalog = @(Get-Content -Raw $CatalogPath | ConvertFrom-Json)
}

if ([string]::IsNullOrWhiteSpace($Prefix)) {
    $Prefix = '{0}_{1}' -f $Brightness, $Categories[0]
}

$targetDir = Join-Path $RepoRoot "assets\wallpapers\$Brightness"
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

$extra = ConvertFrom-JsonObject -Json $ExtraInputJson

for ($i = 0; $i -lt $Count; $i++) {
    $name = Get-NextWallpaperName -Catalog $catalog -NamePrefix $Prefix -Extension $OutputFormat
    $payload = Get-ModelPayload -ModelId $Model -ImagePrompt $Prompt -Size $Resolution -Ratio $AspectRatio -Format $OutputFormat -Extra $extra
    $result = Invoke-FalGeneration -Payload $payload

    if ($DryRun) {
        continue
    }

    $imageUrl = @(Find-ImageUrls -Value $result)[0]
    if ([string]::IsNullOrWhiteSpace($imageUrl)) {
        throw "fal response did not contain an image URL: $($result | ConvertTo-Json -Depth 8)"
    }

    $outputPath = Join-Path $targetDir $name.file
    Invoke-WebRequest -Uri $imageUrl -OutFile $outputPath

    $assetPath = "assets/wallpapers/$Brightness/$($name.file)"
    Add-WallpaperToCatalog -Id $name.id -AssetPath $assetPath
    $catalog += [pscustomobject]@{ id = $name.id }

    Write-Host "Added $assetPath"
}
