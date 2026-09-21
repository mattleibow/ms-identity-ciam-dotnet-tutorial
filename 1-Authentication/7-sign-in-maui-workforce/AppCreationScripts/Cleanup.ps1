#Requires -Version 7

<#
.SYNOPSIS
    Deletes the workforce app registration created by Configure.ps1.

.DESCRIPTION
    Restores safe placeholders for the single-tenant native sample. It does not
    delete tenant resources other than the app registration identified by AppId.
#>

[CmdletBinding()]
param(
    [string] $TenantId,
    [Parameter(Mandatory)]
    [string] $AppId,
    [ValidateSet("Global", "AzureChinaCloud", "AzureUSGovernment")]
    [string] $AzureEnvironmentName = "Global"
)

$ErrorActionPreference = "Stop"
$ProjectDir = Resolve-Path (Join-Path $PSScriptRoot "..")

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Applications)) {
    Install-Module Microsoft.Graph.Applications -Scope CurrentUser -Force
}
Import-Module Microsoft.Graph.Applications

Connect-MgGraph `
    -TenantId $TenantId `
    -Scopes "Application.ReadWrite.All" `
    -Environment $AzureEnvironmentName `
    -NoWelcome

try {
    $app = Get-MgApplication -ApplicationId $AppId
    Remove-MgApplication -ApplicationId $app.Id
    Write-Host "Deleted app registration '$($app.DisplayName)' ($($app.AppId))."

    $settingsPath = Join-Path $ProjectDir "appsettings.json"
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    $settings.AzureAd.Authority = "https://login.microsoftonline.com/Enter_the_Tenant_Id_Here"
    $settings.AzureAd.ClientId = "Enter_the_Application_Id_Here"
    $settings.DownstreamApi.Scopes = @("User.Read")
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8

    foreach ($platformFile in @(
        (Join-Path $ProjectDir "Platforms" "Android" "AndroidManifest.xml"),
        (Join-Path $ProjectDir "Platforms" "iOS" "Info.plist"),
        (Join-Path $ProjectDir "Platforms" "MacCatalyst" "Info.plist")
    )) {
        (Get-Content $platformFile -Raw) `
            -replace "msal[a-f0-9-]+", "msalEnter_the_Application_Id_Here" |
            Set-Content $platformFile -Encoding UTF8
    }
}
finally {
    Disconnect-MgGraph | Out-Null
}
