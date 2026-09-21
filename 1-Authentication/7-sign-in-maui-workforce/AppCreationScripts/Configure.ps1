#Requires -Version 7

<#
.SYNOPSIS
    Creates a single-tenant Microsoft Entra ID workforce app registration.

.DESCRIPTION
    Creates or reuses a public native client for this sample, configures its
    MSAL and localhost redirects, grants Microsoft Graph User.Read, and updates
    this copied sample's placeholder configuration files. No client secret is used.
#>

[CmdletBinding()]
param(
    [string] $TenantId,
    [string] $AppName = "workforce-dotnet-maui",
    [string] $AppId,
    [ValidateSet("Global", "AzureChinaCloud", "AzureUSGovernment")]
    [string] $AzureEnvironmentName = "Global"
)

$ErrorActionPreference = "Stop"
$ProjectDir = Resolve-Path (Join-Path $PSScriptRoot "..")

foreach ($module in @("Microsoft.Graph.Applications", "Microsoft.Graph.Identity.DirectoryManagement")) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Install-Module $module -Scope CurrentUser -Force
    }
    Import-Module $module
}

Connect-MgGraph `
    -TenantId $TenantId `
    -Scopes "Application.ReadWrite.All", "Organization.Read.All" `
    -Environment $AzureEnvironmentName `
    -NoWelcome

try {
    $context = Get-MgContext
    $tenantId = $context.TenantId
    $tenantDomain = (Get-MgOrganization).VerifiedDomains |
        Where-Object IsDefault |
        Select-Object -ExpandProperty Name
    $authorityHost = switch ($AzureEnvironmentName) {
        "AzureChinaCloud" { "https://login.chinacloudapi.cn/" }
        "AzureUSGovernment" { "https://login.microsoftonline.us/" }
        default { "https://login.microsoftonline.com/" }
    }

    $graphPermission = @{
        ResourceAppId = "00000003-0000-0000-c000-000000000000"
        ResourceAccess = @(
            @{ Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"; Type = "Scope" }
        )
    }
    if ($AppId) {
        $app = Get-MgApplication -ApplicationId $AppId
        Update-MgApplication -ApplicationId $app.Id `
            -SignInAudience "AzureADMyOrg" `
            -IsFallbackPublicClient `
            -RequiredResourceAccess @($graphPermission)
        Write-Host "Using the specified single-tenant app registration '$($app.DisplayName)' ($($app.AppId))."
    } else {
        $app = New-MgApplication `
            -DisplayName $AppName `
            -SignInAudience "AzureADMyOrg" `
            -IsFallbackPublicClient `
            -RequiredResourceAccess @($graphPermission)
        New-MgServicePrincipal -AppId $app.AppId | Out-Null
        Write-Host "Created single-tenant app registration '$AppName' ($($app.AppId))."
    }

    Update-MgApplication -ApplicationId $app.Id -PublicClient @{
        RedirectUris = @("msal$($app.AppId)://auth", "http://localhost")
    }

    $settingsPath = Join-Path $ProjectDir "appsettings.json"
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    $settings.AzureAd.Authority = "$authorityHost$tenantId"
    $settings.AzureAd.ClientId = $app.AppId
    $settings.DownstreamApi.Scopes = @("User.Read")
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8

    foreach ($platformFile in @(
        (Join-Path $ProjectDir "Platforms" "Android" "AndroidManifest.xml"),
        (Join-Path $ProjectDir "Platforms" "iOS" "Info.plist"),
        (Join-Path $ProjectDir "Platforms" "MacCatalyst" "Info.plist")
    )) {
        (Get-Content $platformFile -Raw) `
            -replace "msalEnter_the_Application_Id_Here", "msal$($app.AppId)" |
            Set-Content $platformFile -Encoding UTF8
    }

    Write-Host "Configured workforce tenant $tenantDomain ($tenantId)." -ForegroundColor Green
    Write-Host "Redirect URIs: msal$($app.AppId)://auth, http://localhost"
}
finally {
    Disconnect-MgGraph | Out-Null
}
