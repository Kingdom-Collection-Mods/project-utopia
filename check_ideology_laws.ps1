# Reports ideology lawgroup blocks that lack stances for the mod's custom laws. Read-only.
$root = Join-Path $PSScriptRoot 'common'
$ideologyDir = Join-Path $root 'ideologies'
$lawDir = Join-Path $root 'laws'

$customLaws = @(
    'law_task_forces', 'law_demobilized',
    'law_privatized_bureaucrats',
    'law_compulsory_secondary_school', 'law_compulsory_tertiary_school',
    'law_multicultural_globalism', 'law_neo_ethno_state',
    'law_decolonization',
    'law_social_market_economy', 'law_corporate_economy', 'law_free_market_economy', 'law_state_capitalism_economy',
    'law_public_university', 'law_private_universities',
    'law_mass_surveillance',
    'law_ut_minimum_wage',
    'law_registration_process',
    'law_affirmative_equality', 'law_equal_rights_for_women',
    'law_international_trade', 'law_protectionism_union', 'law_free_trade_union',
    'law_ut_disability_insurance', 'law_private_pension',
    'law_lgbt_rights_0', 'law_lgbt_rights_1', 'law_lgbt_rights_2', 'law_lgbt_rights_3',
    'law_environment_protection_institute', 'law_environment_protection_institute_two',
    'law_environment_protection_institute_three', 'law_no_environment_protection',
    'law_food_safety_protection_institute', 'law_food_safety_protection_institute_two',
    'law_no_food_safety_protection'
)

# Resolve each custom law's lawgroup from the mod's own law definitions
$lawText = (Get-ChildItem $lawDir -Filter *.txt | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }) -join "`n"
$groupOf = @{}
foreach ($law in $customLaws) {
    $m = [regex]::Match($lawText, '(?m)^' + [regex]::Escape($law) + '\s*=\s*\{[^{}]*?\bgroup\s*=\s*(lawgroup_\w+)')
    if ($m.Success) { $groupOf[$law] = $m.Groups[1].Value }
    else { Write-Warning "No lawgroup found for $law in $lawDir" }
}

$lawsByGroup = @{}
foreach ($law in $groupOf.Keys) {
    if (-not $lawsByGroup.ContainsKey($groupOf[$law])) { $lawsByGroup[$groupOf[$law]] = @() }
    $lawsByGroup[$groupOf[$law]] += $law
}

$count = 0
foreach ($file in Get-ChildItem $ideologyDir -Filter *.txt) {
    $depth = 0; $ideology = $null; $group = $null; $start = 0; $have = @()
    $lineNo = 0
    foreach ($line in [IO.File]::ReadLines($file.FullName)) {
        $lineNo++
        $t = $line -replace '#.*', ''
        if ($depth -eq 0 -and $t -match '^\s*(\w+)\s*=\s*\{') { $ideology = $Matches[1] }
        if ($depth -eq 1 -and $t -match '^\s*(lawgroup_\w+)\s*=\s*\{') {
            $group = $Matches[1]; $start = $lineNo; $have = @()
        }
        elseif ($group -and $depth -eq 2 -and $t -match '^\s*(\w+)\s*=') { $have += $Matches[1] }

        $depth += ([regex]::Matches($t, '\{')).Count - ([regex]::Matches($t, '\}')).Count

        if ($group -and $depth -eq 1 -and $t -match '\}') {
            if ($lawsByGroup.ContainsKey($group)) {
                $missing = $lawsByGroup[$group] | Where-Object { $have -notcontains $_ }
                if ($missing) {
                    $count++
                    "{0}:{1}  {2}  {3}  missing: {4}" -f $file.Name, $start, $ideology, $group, ($missing -join ', ')
                }
            }
            $group = $null
        }
    }
}
"Blocks with missing stances: $count"
