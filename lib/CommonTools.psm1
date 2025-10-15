$StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$LogFile = ".\logs\{$StartTime} DeploymentLog.txt"

function Write-Log {
    param (
        [string]$ModuleName,
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "{$timestamp} [$ModuleName] - $Message"

    Write-RawLog -Message $logEntry
}

function Write-RawLog {
    param (
        [string]$Message
    )
    
    if (-not (Test-Path -Path $LogFile)) {
        New-Item -Path $LogFile -ItemType File -Force | Out-Null
    }
    Add-Content -Path $LogFile -Value $Message
    Write-Host $Message
}


function Out-Banner {
    param (
        [string]$Path
    )

    $banner = Get-Content -Path $Path
    if ($banner) {
        $banner | ForEach-Object { Write-RawLog -Message $_ }
    } else {
        Write-Log -ModuleName "Banner" -Message "Banner file not found at path: $Path"
    }
}

function Get-RawProperty {
    param (
        [object]$Object
    )

    foreach ($key in $Object.Keys) {
        [PSCustomObject]@{
            Key = $key
            Value = $Object[$key]
        }
    }
}