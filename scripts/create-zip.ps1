# Create ZIP file for Lambda deployment
param(
    [string]$SourceDir = "dist",
    [string]$OutputFile = "function.zip"
)

Write-Host "Creating ZIP file: $OutputFile from $SourceDir" -ForegroundColor Green

# Remove existing ZIP file
if (Test-Path $OutputFile) {
    Remove-Item $OutputFile -Force
    Write-Host "Removed existing $OutputFile" -ForegroundColor Yellow
}

# Try different methods to create ZIP
$zipCreated = $false

# Method 1: Try .NET Framework
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDir, $OutputFile)
    Write-Host "ZIP created using .NET Framework" -ForegroundColor Green
    $zipCreated = $true
} catch {
    Write-Host ".NET Framework compression not available" -ForegroundColor Yellow
}

# Method 2: Try 7-Zip
if (-not $zipCreated) {
    if (Get-Command 7z -ErrorAction SilentlyContinue) {
        try {
            7z a -tzip $OutputFile "$SourceDir\*"
            Write-Host "ZIP created using 7-Zip" -ForegroundColor Green
            $zipCreated = $true
        } catch {
            Write-Host "7-Zip failed" -ForegroundColor Red
        }
    } else {
        Write-Host "7-Zip not available" -ForegroundColor Yellow
    }
}

# Method 3: Try PowerShell Compress-Archive (PowerShell 5.0+)
if (-not $zipCreated) {
    try {
        Compress-Archive -Path "$SourceDir\*" -DestinationPath $OutputFile -Force
        Write-Host "ZIP created using PowerShell Compress-Archive" -ForegroundColor Green
        $zipCreated = $true
    } catch {
        Write-Host "PowerShell Compress-Archive failed" -ForegroundColor Red
    }
}

if (-not $zipCreated) {
    Write-Host "Could not create ZIP file using any available method" -ForegroundColor Red
    Write-Host "Please manually create $OutputFile from the $SourceDir directory" -ForegroundColor Yellow
    Write-Host "You can use Windows Explorer: right-click $SourceDir folder -> Send to -> Compressed (zipped) folder" -ForegroundColor Yellow
    exit 1
}

Write-Host "ZIP file created successfully: $OutputFile" -ForegroundColor Green 