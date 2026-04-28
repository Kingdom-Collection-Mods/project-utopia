param(
    [Parameter(Mandatory)]
    [string]$FolderPath
)

$statePattern = '(?im)^\s*(STATE_[A-Za-z0-9_]+)\s*=\s*\{'

Get-ChildItem -Path $FolderPath -Filter *.txt -File -Recurse | ForEach-Object {

    $content = Get-Content $_.FullName -Raw
    $matches = [regex]::Matches($content, $statePattern)

    foreach ($match in $matches) {

        $stateName = $match.Groups[1].Value
        $start = $match.Index + $match.Length
        $depth = 1
        $i = $start

        while ($i -lt $content.Length -and $depth -gt 0) {
            if ($content[$i] -eq '{') { $depth++ }
            elseif ($content[$i] -eq '}') { $depth-- }
            $i++
        }

        $stateBlock = $content.Substring($start, $i - $start - 1)

        # -------------------------
        # Rare Earths calculation
        # -------------------------
        $rareEarthsAmount = 0

        # --- Gold mines (simple format) ---
        $goldMineMatches = [regex]::Matches($stateBlock, "building_gold_mine\s*=\s*(\d+)")
        foreach ($m in $goldMineMatches) {
            $rareEarthsAmount += [int]$m.Groups[1].Value
        }

        # --- Gold fields (resource block format) ---
        $resourcePattern = '(?s)resource\s*=\s*\{.*?\}'
        $resourceBlocks = [regex]::Matches($stateBlock, $resourcePattern)

        foreach ($block in $resourceBlocks) {
            $blockText = $block.Value

            if ($blockText -match 'type\s*=\s*"building_gold_field"') {

                # Try undiscovered_amount first
                if ($blockText -match 'undiscovered_amount\s*=\s*(\d+)') {
                    $rareEarthsAmount += [int]$Matches[1]
                }
                elseif ($blockText -match 'discovered_amount\s*=\s*(\d+)') {
                    $rareEarthsAmount += [int]$Matches[1]
                }
            }
        }

        # --- Rubber (4:1) ---
        $rubberTotal = 0
        $rubberMatches = [regex]::Matches($stateBlock, "building_rubber_plantation\s*=\s*(\d+)")
        foreach ($m in $rubberMatches) {
            $rubberTotal += [int]$m.Groups[1].Value
        }
        $rareEarthsAmount += [math]::Floor($rubberTotal / 4)

        # -------------------------
        # Bauxite calculation
        # -------------------------
        $sulfurTotal = 0
        $leadTotal = 0
        
        $sulfurMatches = [regex]::Matches($stateBlock, "building_sulfur_mine\s*=\s*(\d+)")
        foreach ($m in $sulfurMatches) {
            $sulfurTotal += [int]$m.Groups[1].Value
        }
        
        $leadMatches = [regex]::Matches($stateBlock, "building_lead_mine\s*=\s*(\d+)")
        foreach ($m in $leadMatches) {
            $leadTotal += [int]$m.Groups[1].Value
        }

        $bauxiteAmount = [math]::Floor($leadTotal / 2) + $sulfurTotal

        # -------------------------
        # Output
        # -------------------------
        if ($rareEarthsAmount -gt 0) {
@"
s:$stateName = {
    change_resource_potential = {
        type = building_rare_earths_mine
        amount = $rareEarthsAmount
    }
}
"@
        }

        if ($bauxiteAmount -gt 0) {
@"
s:$stateName = {
    change_resource_potential = {
        type = building_bauxite_mine
        amount = $bauxiteAmount
    }
}
"@
        }
    }
}