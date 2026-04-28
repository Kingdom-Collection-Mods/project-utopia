Write-Host "ut_bauxite_spawn"
$file = Join-Path $PSScriptRoot "common\on_actions\ut_bauxite_spawn.txt"
$content = Get-Content $file

$total = 0
$count = 0

foreach ($line in $content) {
    if ($line -match '^\s*amount\s*=\s*(\d+)') {
        $total += [int]$Matches[1]
        $count++
    }
}

Write-Host "Entries : $count"
Write-Host "Total   : $total"


Write-Host "ut_rare_earths_spawn"
$file = Join-Path $PSScriptRoot "common\on_actions\ut_rare_earths_spawn.txt"
$content = Get-Content $file

$total = 0
$count = 0

foreach ($line in $content) {
    if ($line -match '^\s*amount\s*=\s*(\d+)') {
        $total += [int]$Matches[1]
        $count++
    }
}

Write-Host "Entries : $count"
Write-Host "Total   : $total"
