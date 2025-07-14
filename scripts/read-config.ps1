function Read-Config {
    param (
        [string]$ConfigPath
    )

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
