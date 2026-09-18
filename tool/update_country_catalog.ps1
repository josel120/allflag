# Maintenance only: downloads a reviewed offline snapshot, never used by the app.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$catalogPage = (Invoke-WebRequest -UseBasicParsing 'https://flagpedia.net/sovereign-states').Content
$matches = [regex]::Matches($catalogPage, '(?s)<img src="/data/flags/h80/([a-z]{2})\.png[^>]*>\s*<span>(.*?)</span>')
if ($matches.Count -ne 195) { throw 'Source scope changed. Review before updating.' }
$knownYears = @{ ve = 2006; pe = 1950; us = 1960; es = 1981; jp = 1999 }
$nameOverrides = @{ ci = 'Ivory Coast'; st = 'Sao Tome and Principe' }
$dataDirectory = Join-Path $projectRoot 'assets/data'
$flagDirectory = Join-Path $projectRoot 'assets/flags'
New-Item -ItemType Directory -Force $dataDirectory, $flagDirectory | Out-Null
$countries = @()
$provenance = @()
foreach ($match in $matches) {
    $code = $match.Groups[1].Value
    $name = [System.Net.WebUtility]::HtmlDecode($match.Groups[2].Value)
    if ($nameOverrides.ContainsKey($code)) { $name = $nameOverrides[$code] }
    $url = "https://flagcdn.com/w2560/$code.png"
    $assetPath = Join-Path $flagDirectory "$code.png"
    Invoke-WebRequest -UseBasicParsing $url -OutFile $assetPath
    $bytes = [System.IO.File]::ReadAllBytes($assetPath)
    if ($bytes.Length -lt 24 -or $bytes[0] -ne 137 -or $bytes[1] -ne 80) { throw "Invalid PNG: $code" }
    $width = [int]($bytes[16] * 16777216 + $bytes[17] * 65536 + $bytes[18] * 256 + $bytes[19])
    $height = [int]($bytes[20] * 16777216 + $bytes[21] * 65536 + $bytes[22] * 256 + $bytes[23])
    $year = $knownYears[$code]
    $id = if ($null -eq $year) { "$code-current" } else { "$code-$year" }
    $countries += [ordered]@{
        code = $code.ToUpperInvariant(); name = $name
        flag = [ordered]@{ id = $id; name = "Flag of $name"; asset = "assets/flags/$code.png"; startYear = $year }
    }
    $provenance += [ordered]@{
        code = $code.ToUpperInvariant(); source = $url; width = $width; height = $height
        sha256 = (Get-FileHash -Algorithm SHA256 $assetPath).Hash.ToLowerInvariant()
    }
}
$countries = @($countries | Sort-Object { $_.name.ToLowerInvariant() })
[System.IO.File]::WriteAllText((Join-Path $dataDirectory 'countries.json'), (ConvertTo-Json -InputObject $countries -Depth 5) + [Environment]::NewLine)
$snapshot = [ordered]@{
    retrieved = (Get-Date -Format 'yyyy-MM-dd'); scope = 'https://flagpedia.net/sovereign-states'
    license = 'https://flagpedia.net/terms'; assets = $provenance
}
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'docs/flag-assets.json'), (ConvertTo-Json $snapshot -Depth 5) + [Environment]::NewLine)
Write-Output "Updated $($countries.Count) countries and PNGs. Review data, artwork and provenance before committing."
