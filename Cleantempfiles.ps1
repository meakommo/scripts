# Define the directories to be cleaned
$directories = @(
    "$env:windir\Temp",
    "$env:windir\SoftwareDistribution\Download",
    "$env:windir\Prefetch"
)

# Define the file extensions to be deleted
$extensions = @(
    "*.tmp",
    "*.log",
    "*.old"
)

# Loop through each directory
foreach ($directory in $directories) {
    # Check if the directory exists
    if (Test-Path $directory) {
        # Loop through each file extension
        foreach ($extension in $extensions) {
            # Delete all files with the specified extension in the directory
            Get-ChildItem $directory -Include $extension -Recurse | Remove-Item
        }
    }
}

# Clear the recycle bin
Clear-RecycleBin

# Display a message indicating that the cleaning is complete
Write-Host "Cleaning complete!"
