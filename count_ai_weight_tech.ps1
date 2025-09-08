param(
    [string]$FilePath
)

if (-not (Test-Path $FilePath)) {
    Write-Host "File not found: $FilePath"
    exit 1
}

# Hashtable to store counts
$counts = @{}

# Read file and process lines
Get-Content $FilePath | ForEach-Object {
    if ($_ -match 'value\s*=\s*([0-9.]+)') {
        $val = $matches[1]
        if ($counts.ContainsKey($val)) {
            $counts[$val]++
        } else {
            $counts[$val] = 1
        }
    }
}

Write-Host "in file $FilePath"
foreach ($key in ($counts.Keys | Sort-Object {[double]$_} -Descending)) {
    Write-Host "${key}: $($counts[$key]) occurences"
}