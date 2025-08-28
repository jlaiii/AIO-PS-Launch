# AIO Script Launcher
# Updated to use the ./assets/ directory correctly

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "           All-In-One Tool Launcher" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$AssetsPath = $PSScriptRoot
$ConfigFile = Join-Path -Path $AssetsPath -ChildPath "scripts.txt"

# Create the assets directory if it doesn't exist (should already exist, but just in case)
if (-not (Test-Path $AssetsPath)) {
    New-Item -ItemType Directory -Path $AssetsPath -Force | Out-Null
    Write-Host "Created assets directory." -ForegroundColor Yellow
}

# Check if the config file exists
if (-not (Test-Path $ConfigFile)) {
    # Create a default config file if it doesn't exist
    $DefaultConfig = @"
# AIO Tool Launcher Configuration
# Add your scripts below in the format: Nickname|URL|LocalFileName
# Use the '#' character for comments.

Windows Toolbox|https://christitus.com/win|win-toolbox.ps1
Activated.win|https://get.activated.win|activated-win.ps1
"@
    $DefaultConfig | Out-File -FilePath $ConfigFile -Encoding utf8
    Write-Host "Created default scripts.txt configuration file." -ForegroundColor Yellow
    Write-Host "Please edit .\assets\scripts.txt to add your own tools." -ForegroundColor Yellow
    Write-Host ""
}

# Read the configuration file
$AvailableScripts = @()
Write-Host "Reading configuration from $ConfigFile..." -ForegroundColor Yellow

Get-Content $ConfigFile | ForEach-Object {
    $line = $_.Trim()
    # Skip empty lines and comments
    if ($line -and !$line.StartsWith('#')) {
        $parts = $line -split '\|', 3
        if ($parts.Count -eq 3) {
            $AvailableScripts += [PSCustomObject]@{
                Name = $parts[0].Trim()    # Nickname
                Url  = $parts[1].Trim()    # URL
                File = $parts[2].Trim()    # Local Filename
            }
        }
    }
}

if ($AvailableScripts.Count -eq 0) {
    Write-Host "ERROR: No valid scripts found in configuration file!" -ForegroundColor Red
    Write-Host "Please edit $ConfigFile and add your tools." -ForegroundColor Yellow
    pause
    exit
}

# Display the menu
Write-Host "`nPlease select a tool to run:`n" -ForegroundColor White

for ($i = 0; $i -lt $AvailableScripts.Count; $i++) {
    Write-Host "$($i+1). $($AvailableScripts[$i].Name)" -ForegroundColor Cyan
}

Write-Host "`n0. Exit" -ForegroundColor Gray
Write-Host ""

# Get user selection
do {
    $choice = Read-Host "Enter your choice (0-$($AvailableScripts.Count))"
    $isValid = [int]::TryParse($choice, [ref]$null) -and $choice -ge 0 -and $choice -le $AvailableScripts.Count
    if (-not $isValid) {
        Write-Host "Invalid choice. Please try again." -ForegroundColor Red
    }
} until ($isValid)

if ($choice -eq 0) {
    Write-Host "Goodbye!" -ForegroundColor Yellow
    timeout /t 2 > $null
    exit
}

$SelectedScript = $AvailableScripts[$choice-1]
$ScriptPath = Join-Path -Path $AssetsPath -ChildPath $SelectedScript.File

Write-Host "`nYou selected: $($SelectedScript.Name)" -ForegroundColor Green
Write-Host ""

# Check if local script exists or download it
if (Test-Path $ScriptPath) {
    Write-Host ":: Found local script. Running offline version..." -ForegroundColor Green
}
else {
    Write-Host ":: Local script not found." -ForegroundColor Yellow
    Write-Host ":: Attempting to download from the internet..." -ForegroundColor Yellow

    try {
        Invoke-WebRequest -Uri $SelectedScript.Url -UseBasicParsing -OutFile $ScriptPath -ErrorAction Stop
        Write-Host ":: Download successful!" -ForegroundColor Green
    }
    catch {
        Write-Host ":: ERROR: Failed to download the script!" -ForegroundColor Red
        Write-Host ":: $($_.Exception.Message)" -ForegroundColor Gray
        Write-Host ":: Please check your internet connection and try again." -ForegroundColor Yellow
        pause
        exit
    }
}

# Run the selected script
Write-Host ":: Launching $($SelectedScript.Name)..." -ForegroundColor Green
Write-Host "`n" + ("=" * 50) + "`n" -ForegroundColor Cyan

Set-ExecutionPolicy Bypass -Scope Process -Force
& $ScriptPath

# Pause after script finishes
Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
Write-Host ":: $($SelectedScript.Name) has finished." -ForegroundColor Green
pause