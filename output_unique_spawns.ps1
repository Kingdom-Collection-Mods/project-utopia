# Initialize hash table to group by rarity
$groups = @{
    small = @()
    medium = @()
    large = @()
    tiny = @()
}

Get-ChildItem -Filter *.txt | ForEach-Object {
    $lines = Get-Content $_.FullName
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '#unique rare earths mining (small|medium|large|tiny)') {
            $rarityMatch = [regex]::Match($lines[$i], '#unique rare earths mining (small|medium|large|tiny)')
            $rarity = $rarityMatch.Groups[1].Value

            # Walk backwards to find the nearest STATE_ line
            for ($j = $i; $j -ge 0; $j--) {
                $stateMatch = [regex]::Match($lines[$j], '^STATE_([A-Z0-9_]+)\s*=')
                if ($stateMatch.Success) {
                    $stateRaw = $stateMatch.Groups[1].Value

                    # Format state name
                    $words = ($stateRaw -replace '_', ' ').ToLower().Split(' ')
                    $capitalized = @()
                    foreach ($word in $words) {
                        if ($word.Length -gt 0) {
                            $capitalized += $word.Substring(0,1).ToUpper() + $word.Substring(1)
                        }
                    }
                    $formatted = $capitalized -join ' '

                    # Add to corresponding group
                    $groups[$rarity] += $formatted
                    break
                }
            }
        }
    }
}

# Output all groups in order: large, medium, small
foreach ($rarity in @('Large', 'Medium', 'Small', 'Tiny')) {
    if ($groups[$rarity].Count -gt 0) {
        $states = $groups[$rarity] -join ', '
        Write-Output "${rarity}: $states"
    }
}
