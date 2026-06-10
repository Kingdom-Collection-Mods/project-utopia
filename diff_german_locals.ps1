$repoRoot = Split-Path -Parent $PSScriptRoot
$en = Join-Path $repoRoot 'localization\english\ut_l_english.yml'
$de = Join-Path $repoRoot 'localization\german\ut_l_german.yml'

$pattern = '^\s*([^#\s][^:]*):'

# Load English data and store line numbers
$enLines = Get-Content $en
$enData = @()
for ($i = 0; $i -lt $enLines.Count; $i++) {
    if ($enLines[$i] -match $pattern) {
        $enData += [PSCustomObject]@{
            Key  = $matches[1].Trim()
            Line = $enLines[$i]
            Index = $i + 1
        }
    }
}

$deKeys = Get-Content $de | ForEach-Object {
    if ($_ -match $pattern) { $matches[1].Trim() }
} | Where-Object { $_ } | Sort-Object -Unique

# Filter for missing keys
$missing = $enData | Where-Object { 
    $_.Key -ne 'l_english' -and $_.Key -notin $deKeys 
} | Sort-Object Index

"Missing count: $($missing.Count)"
$missing | ForEach-Object {
    Write-Output "$($_.Key) @ localization\german\ut_l_german.yml:$($_.Index)"
}