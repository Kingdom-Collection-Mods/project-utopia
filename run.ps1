# Save the current directory
$originalDir = Get-Location

# Navigate to the target directory
Set-Location "D:\Projects\Phyton Projects\PyHelpersForPDXWikis"

# Run the Python script
python -m vic3.PMSpreadsheet.generate_spreadsheets

# Define the source file path and the destination file path
$sourceFile = "D:\Projects\Phyton Projects\PyHelpersForPDXWikis\output\vic3\1.8.6\Spreadsheets\production_methods.txt"
$destinationFile = "$originalDir\production_methods.txt"

# Move the file to the original directory
if (Test-Path $sourceFile) {
    Move-Item -Path $sourceFile -Destination $destinationFile
    Write-Host "File moved to $destinationFile"
} else {
    Write-Host "Source file not found: $sourceFile"
}

# Return to the original directory
Set-Location $originalDir
