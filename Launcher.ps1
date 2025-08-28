# AIO Script Launcher
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "           All-In-One Tool Launcher" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Read the configuration file
$ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "scripts.txt"
$AvailableScripts = @()

if (-not (Test-Path $ConfigFile)) {
    Write-Host "ERROR: Configuration file 'scripts.txt' not found!" -ForegroundColor Red
    Write-Host "Please create it in the same folder as this launcher." -ForegroundColor Yellow
    pause
    exit
}

Write-Host "Reading configuration..." -ForegroundColor Yellow
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
$ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath $SelectedScript.File

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