# Define UTF-8 with BOM encoding
$utf8bom = New-Object System.Text.UTF8Encoding $true

# File extensions to process
$extensions = @("*.txt", "*.yml")

# Process each file type
foreach ($ext in $extensions) {
    Get-ChildItem -Path . -Recurse -File -Filter $ext | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        [System.IO.File]::WriteAllText($_.FullName, $content, $utf8bom)
    }
}
