function Read-Config {
    param (
        [string]$ConfigPath
    )

<<<<<<< HEAD
    if (-Not (Test-Path $ConfigPath)) {
        throw "Config file not found at $ConfigPath"
    }

    $rawJson = Get-Content $ConfigPath -Raw
    $rawConfig = $rawJson | ConvertFrom-Json

    # Force paths into a hashtable
    $resolvedPaths = @{}
    foreach ($entry in $rawConfig.paths.PSObject.Properties) {
        $resolvedPaths[$entry.Name] = $entry.Value
    }
    $rawConfig.paths = $resolvedPaths

    return $rawConfig
}
=======
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
>>>>>>> 33040da48db7ebdcc8d1d8b5f045b28ed9d61454
