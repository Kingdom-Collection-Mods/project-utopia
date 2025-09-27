param(
    [Parameter(Mandatory)]
    [string]$Path
)

if (-not (Test-Path $Path)) {
    Write-Host "File not found: $Path" -ForegroundColor Red
    exit 1
}

# Read file preserving line endings
$lines = Get-Content -Path $Path

# Use a real stack
$stack = New-Object System.Collections.Stack
$errors = New-Object System.Collections.Generic.List[string]

$lineNo = 0
foreach ($rawLine in $lines) {
    $lineNo++
    $line = $rawLine

    # Strip comments starting with # (typical for Paradox scripts)
    $hash = $line.IndexOf('#')
    if ($hash -ge 0) { $line = $line.Substring(0, $hash) }

    # Simple string state so we ignore braces inside quotes
    $inString = $false
    for ($i = 0; $i -lt $line.Length; $i++) {
        $ch = $line[$i]

        if ($ch -eq '"') {
            $inString = -not $inString
            continue
        }
        if ($inString) { continue }

        if ($ch -eq '{') {
            # store 1-based position for nicer messages
            $stack.Push([pscustomobject]@{ Line = $lineNo; Col = $i + 1 })
        }
        elseif ($ch -eq '}') {
            if ($stack.Count -eq 0) {
                $errors.Add("Extra closing '}' at line $lineNo, col $($i + 1)")
            } else {
                $null = $stack.Pop()
            }
        }
    }
}

# Any openings left unmatched?
foreach ($open in $stack) {
    $errors.Add("Missing closing '}' for opening at line $($open.Line), col $($open.Col)")
}

if ($errors.Count -eq 0) {
    Write-Host "All braces match!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Brace issues found:" -ForegroundColor Yellow
    $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    exit 2
}
