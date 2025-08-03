param(
    [string]$ResourceName = "bg_rare_earths_mining"
)

$folder = "d:\Freddy\Documents\Paradox Interactive\Victoria 3\mod\project-utopia\map_data\state_regions"
$amount = 0

Get-ChildItem -Path $folder -Filter *.txt | ForEach-Object {
    $content = Get-Content $_.FullName

    # Sum resource blocks
    $resourceBlocks = ($content -join "`n") -split "resource\s*=\s*{"
    foreach ($block in $resourceBlocks) {
        if ($block -match "type\s*=\s*`"$ResourceName`"") {
            if ($block -match 'undiscovered_amount\s*=\s*(\d+)') {
                $amount += [int]$matches[1]
            }
        }
    }

    # Sum direct assignments
    foreach ($line in $content) {
        if ($line -match "$ResourceName\s*=\s*(\d+)") {
            $amount += [int]$matches[1]
        }
    }
}

Write-Host "Total $ResourceName amount: $amount"