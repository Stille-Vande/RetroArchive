Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Check for core directories; sync from GitHub if missing
$expectedDirs = @("archive", "config", "inbound", "logs", "scripts", "tools")
$missing = $false
foreach ($dir in $expectedDirs) {
    if (-not (Test-Path (Join-Path $PSScriptRoot $dir))) {
        $missing = $true
        break
    }
}

if ($missing) {
    Write-Host "Missing directories detected. Syncing from GitHub..."
    $zipUrl = "https://github.com/Stille-Vande/RetroArchive/archive/refs/heads/main.zip"
    $tempZip = Join-Path $env:TEMP "RetroArchive-main.zip"
    $extractPath = Join-Path $env:TEMP "RetroArchive-main"

    Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $env:TEMP)

    Copy-Item -Path (Join-Path $extractPath "*") -Destination $PSScriptRoot -Recurse -Force
    Remove-Item $tempZip -Force
    Remove-Item $extractPath -Recurse -Force
}

# Prepare logging early
$logReady = Test-Path "$PSScriptRoot\logs"
$logFilePath = "$PSScriptRoot\logs\retroarchive.log"

function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "DEBUG", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"
    Write-Host $logLine
    if ($logReady) {
        Add-Content -Path $logFilePath -Value $logLine
    }
}

Write-Log "RetroArchive started."

# Load config
. "$PSScriptRoot\scripts\read-config.ps1"
$global:config = Read-Config -ConfigPath "$PSScriptRoot\config\settings.json"

Write-Host "Loaded config:" ($global:config | ConvertTo-Json -Depth 5)
Write-Log "Loaded configuration: $(($global:config | ConvertTo-Json -Depth 5))" "DEBUG"

# Debug message box with resolved paths
$resolvedPaths = @{}
foreach ($key in $global:config.paths.Keys) {
    $path = Join-Path $PSScriptRoot $global:config.paths[$key]
    try {
        $resolvedPaths[$key] = (Resolve-Path $path -ErrorAction Stop).Path
    } catch {
        $resolvedPaths[$key] = "(not found)"
    }
}
[System.Windows.Forms.MessageBox]::Show("Resolved paths:`n$($resolvedPaths | ConvertTo-Json -Depth 2)", "Debug: Paths Loaded")

# Check for ROMs directory and set config accordingly
$parentRomsPath = Join-Path (Split-Path $PSScriptRoot -Parent) "roms"
$localRomsPath = Join-Path $PSScriptRoot "roms"

if (Test-Path $parentRomsPath) {
    $global:config.paths.roms = "..\roms"
    Write-Log "Detected RetroBat-style setup. Using parent roms directory." "INFO"
} else {
    if (-not (Test-Path $localRomsPath)) {
        New-Item -ItemType Directory -Path $localRomsPath | Out-Null
        Write-Log "Created local roms directory." "INFO"
    }
    $global:config.paths.roms = "roms"
    Write-Log "No parent roms directory found. Using local roms." "INFO"
}

# Save updated config
$jsonPath = Join-Path $PSScriptRoot "config\settings.json"
$json = $global:config | ConvertTo-Json -Depth 5
Set-Content -Path $jsonPath -Value $json

# Update logging flags after config is loaded
function Should-Log {
    param ([string]$Level = "INFO")
    if (-not $global:config.logging.enabled) { return $false }
    if ($Level -eq "DEBUG" -and -not $global:config.logging.debug) { return $false }
    return $true
}

# Overwrite logging with config-aware logic
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "DEBUG", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"
    Write-Host $logLine
    if (Should-Log -Level $Level) {
        Add-Content -Path $logFilePath -Value $logLine
    }
}

# Folder picker dialog
function Pick-Folder {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.ShowNewFolderButton = $true
    if ($dialog.ShowDialog() -eq "OK") {
        return $dialog.SelectedPath
    }
    return $null
}

# Update config file on disk
function Update-ConfigPath {
    param (
        [string]$Key,
        [string]$NewValue
    )
    $global:config.paths[$Key] = $NewValue
    $jsonPath = Join-Path $PSScriptRoot "config\settings.json"
    $json = $global:config | ConvertTo-Json -Depth 5
    Set-Content -Path $jsonPath -Value $json
    Write-Log "Updated path '$Key' to '$NewValue'" "INFO"
}

# Check for required tools presence
$toolsPath = Join-Path $PSScriptRoot $global:config.paths.tools
$chdmanPath = Join-Path $toolsPath "chdman.exe"
$sevenZipPath = Join-Path $toolsPath "7z.exe"

if (-not (Test-Path $chdmanPath)) {
    Write-Log "chdman.exe not found in $toolsPath" "WARNING"
}
if (-not (Test-Path $sevenZipPath)) {
    Write-Log "7z.exe not found in $toolsPath" "WARNING"
}

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "RetroArchive"
$form.Size = New-Object System.Drawing.Size(700, 500)
$form.StartPosition = "CenterScreen"

# Vertical spacing start
$y = 20

# Dynamically create labels + buttons for each path
foreach ($key in $global:config.paths.Keys) {
    $pathValue = $global:config.paths[$key]
    $resolved = $null
    try {
        $resolved = (Resolve-Path -Path (Join-Path $PSScriptRoot $pathValue) -ErrorAction Stop).Path
    } catch {
        $resolved = "(not found)"
    }
    $absolutePath = $resolved

    # Label showing the absolute path
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "$key`: $absolutePath"
    $label.Size = New-Object System.Drawing.Size(560, 23)
    $label.Location = [System.Drawing.Point]::new(20, $y)
    $form.Controls.Add($label)

    # Button to change path
    $button = New-Object System.Windows.Forms.Button
    $button.Text = "Change"
    $button.Size = New-Object System.Drawing.Size(80, 23)
    $button.Location = [System.Drawing.Point]::new(600, $y)

    # Capture variables for closure
    $localKey = $key
    $localLabel = $label

    $button.Add_Click({
        $newPath = Pick-Folder
        if ($newPath) {
            Update-ConfigPath -Key $localKey -NewValue $newPath
            $localLabel.Text = "$localKey`: $newPath"
        }
    })

    $form.Controls.Add($button)
    $y += 35
}

# Close button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Exit"
$closeButton.Size = New-Object System.Drawing.Size(80, 30)
$closeButton.Location = [System.Drawing.Point]::new(300, $y + 10)
$closeButton.Add_Click({ $form.Close() })
$form.Controls.Add($closeButton)

# Run form
[System.Windows.Forms.Application]::Run($form)
