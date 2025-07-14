function Read-Config {
    param (
        [string]$ConfigPath
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "Config file not found: $ConfigPath"
    }

    $json = Get-Content -Path $ConfigPath -Raw
    return $json | ConvertFrom-Json
}

# Example usage:
# $config = Read-Config -ConfigPath ".\config\settings.json"
# $config.paths | Format-List
# $config.versions | Format-List
