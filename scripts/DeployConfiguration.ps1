param(
    [string]$ConfigPath = ".\data\configurations"
)


".\lib" | Get-ChildItem -Include "*.psm1", "*.ps1", "*.psd1" -Recurse -File | Import-Module

Import-Module Microsoft.Xrm.Tooling.CrmConnector.PowerShell.psd1 -Force
Import-Module Microsoft.Xrm.Data.PowerShell.psd1 -Force

Import-Module .\scripts\ConfigPublisher.psm1 -Force

Out-Banner -Path ".\data\Banner.txt"
Write-Log -ModuleName $MyInvocation.MyCommand.Name -Message "Connecting to Dynamics 365..."

$connection = Get-CrmConnection -InteractiveMode

Write-Log -ModuleName $MyInvocation.MyCommand.Name -Message "Starting config publisher..."

$allFiles = Get-ChildItem -Path $ConfigPath -Filter "*.json" -Recurse -ErrorAction SilentlyContinue | Sort-Object file

Publish-Configuration -Files $allFiles -CrmConnection $connection

Write-Log -ModuleName $MyInvocation.MyCommand.Name -Message "Configuration publishing completed."