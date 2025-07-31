# Define source file
$sourceFile = "localization\english\ut_l_english.yml"

# Define target languages
$languages = @("braz_por", "french", "japanese", "korean", "polish", "russian", "simp_chinese", "spanish", "turkish")

# Read all lines from the source file
if (!(Test-Path $sourceFile)) {
    Write-Error "Source file not found: $sourceFile"
    exit 1
}

$content = Get-Content $sourceFile

# Ensure the file starts with "l_english:"
if ($content[0] -notmatch "^l_english:") {
    Write-Error "First line of the source file is not 'l_english:'"
    exit 1
}

foreach ($lang in $languages) {
    $targetDir = "localization\$lang"
    $targetFile = "$targetDir\ut_l_${lang}.yml"

    # Ensure the target directory exists
    if (!(Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    # Replace the first line with the new language header
    $newContent = @("l_${lang}:") + $content[1..($content.Length - 1)]


    # Write the modified content to the new file
    $newContent | Set-Content -Encoding utf8BOM -Path $targetFile

    Write-Host "Generated $targetFile"
}
