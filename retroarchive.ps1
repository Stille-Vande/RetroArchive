# retroarchive.ps1 - Main GUI + GitHub sync bootstrap

# Define repo info
$repoOwner = "Stille-Vande"
$repoName  = "RetroArchive"
$branch    = "main"
$zipUrl    = "https://github.com/$repoOwner/$repoName/archive/refs/heads/$branch.zip"

# Root folder (where this script runs)
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Sync repo by downloading & extracting if not already present
function Sync-GitHub {
    $scriptsPath = Join-Path $root "scripts"
    if (-not (Test-Path $scriptsPath)) {
        Write-Host "Downloading RetroArchive repo from GitHub..."
        $tempZip = "$env:TEMP\$repoName.zip"
        $tempExtract = "$env:TEMP\$repoName"

        Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip
        Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

        Copy-Item -Path (Join-Path $tempExtract "$repoName-$branch\*") -Destination $root -Recurse -Force

        Remove-Item $tempZip -Force
        Remove-Item $tempExtract -Recurse -Force

        Write-Host "Repo synced. Please rerun the script."
        exit
    }
    else {
        Write-Host "Repo already synced."
    }
}

# Read settings.json from config folder
function Read-Config {
    param ([string]$ConfigPath)

    if (-not (Test-Path $ConfigPath)) {
        throw "Config file not found: $ConfigPath"
    }

    $json = Get-Content -Path $ConfigPath -Raw
    return $json | ConvertFrom-Json
}

# Show main menu options
function Show-Menu {
    Clear-Host
    Write-Host "RetroArchive Main Menu" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host "1. Sync with GitHub"
    Write-Host "2. Initialize/Check Folders"
    Write-Host "3. Convert CHD Files"
    Write-Host "4. Exit"
    Write-Host ""
}

# Main menu loop
function Main {
    Sync-GitHub

    $configPath = Join-Path $root "config\settings.json"
    $config = Read-Config -ConfigPath $configPath

    do {
        Show-Menu
        $choice = Read-Host "Enter choice (1-4)"
        switch ($choice) {
            '1' { Sync-GitHub }
            '2' { Write-Host "Initialize/Check Folders - TODO" -ForegroundColor Yellow }
            '3' { Write-Host "Convert CHD Files - TODO" -ForegroundColor Yellow }
            '4' {
                Write-Host "Exiting RetroArchive. Goodbye!" -ForegroundColor Green
                break
            }
            default { Write-Host "Invalid choice. Try again." -ForegroundColor Red }
        }
    } while ($true)
}

Main
