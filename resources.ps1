param(
    [Parameter(Mandatory)]
    [string]$FolderPath,
    
    [Parameter(Mandatory)]
    [int]$Resource
)
# ---- CUSTOM EXTRA (per state) ----

$customRareEarths = @{
    # --- LARGE (60) ---
    "STATE_CALIFORNIA"       = 60
    "STATE_HINGGAN"          = 60

    # --- MEDIUM (40) ---
    "STATE_SOUTH_MADAGASCAR" = 40
    "STATE_CONGO"            = 40
    "STATE_TONKIN"           = 40
    "STATE_MALAYA"           = 40
    "STATE_KOLA"             = 40
    "STATE_SICHUAN"           = 40

    # --- SMALL (20) ---
    "STATE_NORRLAND"              = 20
    "STATE_QUEBEC"                = 20
    "STATE_NORTHWEST_TERRITORIES" = 20
    "STATE_BAJA_CALIFORNIA"       = 20
    "STATE_FORMOSA"               = 20
    "STATE_GUANGDONG"             = 20
    "STATE_SHAOZHOU"              = 20
    "STATE_BOTSWANA"           = 20

    # --- TINY (10) ---
    "STATE_RHONE"          = 10
    "STATE_AQUITAINE"      = 10
    "STATE_BAVARIA"        = 10
    "STATE_SAXONY"         = 10
    "STATE_WESTERN_SERBIA" = 10
    "STATE_TALLINN"        = 10
}

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
        $goldTotal = 0
        $rubberTotal = 0

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

                if ($blockText -match 'undiscovered_amount\s*=\s*(\d+)') {
                    $goldTotal += [int]$Matches[1]
                }
                elseif ($blockText -match 'discovered_amount\s*=\s*(\d+)') {
                    $goldTotal += [int]$Matches[1]
                }
            }
            
            if ($blockText -match 'type\s*=\s*"building_rubber_plantation"') {

                if ($blockText -match 'undiscovered_amount\s*=\s*(\d+)') {
                    $rubberTotal += [int]$Matches[1]
                }
                elseif ($blockText -match 'discovered_amount\s*=\s*(\d+)') {
                    $rubberTotal += [int]$Matches[1]
                }
            }
        }

        # --- Rubber (4:1) ---
        $rubberTotal = [math]::Floor($rubberTotal / 4)


        $rareEarthsAmount = $goldTotal + $rubberTotal
        
        if ($customRareEarths.ContainsKey($stateName)) {
            $rareEarthsAmount += $customRareEarths[$stateName]
        }

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

        $bauxiteAmount = [math]::Max([math]::Floor($leadTotal / 2), $sulfurTotal)

        # -------------------------
        # Output
        # -------------------------
        if (($Resource -eq 0) -and ($rareEarthsAmount -gt 0)) {
@"
s:$stateName = {
    change_resource_potential = {
        type = building_rare_earths_mine
        amount = $rareEarthsAmount
    }
}
"@
        }

        if (($Resource -eq 1) -and ($bauxiteAmount -gt 0)) {
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

#Initially AI generated