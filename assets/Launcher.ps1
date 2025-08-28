# AIO Script Launcher with Status on Main Menu
# Shows download status immediately when launched

function Get-Config {
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "scripts.txt"
    
    if (-not (Test-Path $ConfigFile)) {
        # Create default config if it doesn't exist
        $DefaultConfig = @"
# AIO Tool Launcher Configuration
# Format: Nickname|URL|LocalFileName

Windows Toolbox|https://christitus.com/win|win-toolbox.ps1
Activated.win|https://get.activated.win|activated-win.ps1
"@
        $DefaultConfig | Out-File -FilePath $ConfigFile -Encoding utf8
        Write-Host "Created default config file." -ForegroundColor Yellow
    }

    $AvailableScripts = @()
    Get-Content $ConfigFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and !$line.StartsWith('#')) {
            $parts = $line -split '\|', 3
            if ($parts.Count -eq 3) {
                $AvailableScripts += [PSCustomObject]@{
                    Name = $parts[0].Trim()
                    Url  = $parts[1].Trim()
                    File = $parts[2].Trim()
                    Path = Join-Path -Path $PSScriptRoot -ChildPath $parts[2].Trim()
                }
            }
        }
    }
    return $AvailableScripts
}

function Get-DownloadStatus {
    $scripts = Get-Config
    $statusOutput = @()
    $downloadedCount = 0
    
    foreach ($script in $scripts) {
        $isDownloaded = Test-Path $script.Path
        if ($isDownloaded) { $downloadedCount++ }
        
        $statusOutput += [PSCustomObject]@{
            Name = $script.Name
            Status = if ($isDownloaded) { "DOWNLOADED" } else { "MISSING" }
            Color = if ($isDownloaded) { "Green" } else { "Red" }
        }
    }
    
    return @{
        StatusOutput = $statusOutput
        Downloaded = $downloadedCount
        Total = $scripts.Count
    }
}

function Show-MainMenu {
    Clear-Host
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "           All-In-One Tool Launcher" -ForegroundColor White
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Show download status immediately
    $status = Get-DownloadStatus
    Write-Host "Download Status:" -ForegroundColor White
    Write-Host "-----------------------------------------" -ForegroundColor Cyan
    
    foreach ($item in $status.StatusOutput) {
        Write-Host ("{0,-20} [{1}]" -f $item.Name, $item.Status) -ForegroundColor $item.Color
    }
    
    Write-Host "-----------------------------------------" -ForegroundColor Cyan
    Write-Host ("Tools: {0}/{1} Downloaded" -f $status.Downloaded, $status.Total) -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[1] Run a Tool" -ForegroundColor Green
    Write-Host "[2] Download ALL Tools (Fresh Copy)" -ForegroundColor Yellow
    Write-Host "[3] Check Download Status (Detailed)" -ForegroundColor Cyan
    Write-Host "[4] DELETE ALL Local Scripts" -ForegroundColor Red
    Write-Host "[0] Exit" -ForegroundColor Gray
    Write-Host ""
}

function Show-DetailedStatus {
    $scripts = Get-Config
    Write-Host "`nDetailed Download Status:`n" -ForegroundColor White
    Write-Host ("{0,-25} {1,-15} {2,-10}" -f "Tool Name", "Local File", "Status") -ForegroundColor Cyan
    Write-Host ("-" * 60) -ForegroundColor Cyan
    
    foreach ($script in $scripts) {
        $status = if (Test-Path $script.Path) { 
            "DOWNLOADED" 
        } else { 
            "MISSING" 
        }
        $color = if ($status -eq "DOWNLOADED") { "Green" } else { "Red" }
        Write-Host ("{0,-25} {1,-15} {2,-10}" -f $script.Name, $script.File, $status) -ForegroundColor $color
    }
    
    $downloaded = ($scripts | Where-Object { Test-Path $_.Path }).Count
    Write-Host "`nSummary: $downloaded of $($scripts.Count) tools downloaded" -ForegroundColor Yellow
    pause
}

function Download-AllTools {
    $scripts = Get-Config
    Write-Host "`nDownloading ALL tools...`n" -ForegroundColor Yellow
    
    $successCount = 0
    foreach ($script in $scripts) {
        Write-Host "Downloading $($script.Name)..." -ForegroundColor White -NoNewline
        try {
            Invoke-WebRequest -Uri $script.Url -UseBasicParsing -OutFile $script.Path -ErrorAction Stop
            Write-Host " [OK]" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Host " [FAILED]" -ForegroundColor Red
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nDownload completed: $successCount of $($scripts.Count) tools downloaded successfully" -ForegroundColor Yellow
    pause
}

function Delete-AllTools {
    Write-Host "`nWARNING: This will delete ALL local script copies!" -ForegroundColor Red
    Write-Host "You will need to download them again to use offline." -ForegroundColor Yellow
    Write-Host ""
    $confirm = Read-Host "Are you sure? Type 'DELETE' to confirm"
    
    if ($confirm -eq "DELETE") {
        $scripts = Get-Config
        $deletedCount = 0
        foreach ($script in $scripts) {
            if (Test-Path $script.Path) {
                Remove-Item -Path $script.Path -Force -ErrorAction SilentlyContinue
                $deletedCount++
            }
        }
        Write-Host "Deleted $deletedCount local script files." -ForegroundColor Green
    }
    else {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
    }
    pause
}

function Run-ToolMenu {
    $scripts = Get-Config
    if ($scripts.Count -eq 0) {
        Write-Host "ERROR: No tools configured! Edit scripts.txt" -ForegroundColor Red
        pause
        return
    }

    Write-Host "`nPlease select a tool to run:`n" -ForegroundColor White
    for ($i = 0; $i -lt $scripts.Count; $i++) {
        $status = if (Test-Path $scripts[$i].Path) { "[LOCAL]" } else { "[ONLINE]" }
        Write-Host "$($i+1). $($scripts[$i].Name) $status" -ForegroundColor Cyan
    }
    Write-Host "`n0. Back to Main Menu" -ForegroundColor Gray
    Write-Host ""

    do {
        $choice = Read-Host "Enter your choice (0-$($scripts.Count))"
        $isValid = [int]::TryParse($choice, [ref]$null) -and $choice -ge 0 -and $choice -le $scripts.Count
        if (-not $isValid) { Write-Host "Invalid choice." -ForegroundColor Red }
    } until ($isValid)

    if ($choice -eq 0) { return }

    $SelectedScript = $scripts[$choice-1]
    Write-Host "`nYou selected: $($SelectedScript.Name)" -ForegroundColor Green

    # Download if not available locally
    if (-not (Test-Path $SelectedScript.Path)) {
        Write-Host "Downloading latest version..." -ForegroundColor Yellow
        try {
            Invoke-WebRequest -Uri $SelectedScript.Url -UseBasicParsing -OutFile $SelectedScript.Path -ErrorAction Stop
            Write-Host "Download successful!" -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Download failed! Cannot run tool." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Gray
            pause
            return
        }
    }

    # Run the script
    Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    & $SelectedScript.Path
    Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
    Write-Host ":: $($SelectedScript.Name) has finished." -ForegroundColor Green
    pause
}

# Main program loop
do {
    Show-MainMenu
    $mainChoice = Read-Host "Enter your choice [0-4]"
    
    switch ($mainChoice) {
        "1" { Run-ToolMenu }
        "2" { Download-AllTools }
        "3" { Show-DetailedStatus }
        "4" { Delete-AllTools }
        "0" { 
            Write-Host "Goodbye!" -ForegroundColor Yellow
            timeout /t 2 > $null
            exit 
        }
        default { 
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            pause
        }
    }
} while ($true)