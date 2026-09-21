#Requires -Version 7

<#
.SYNOPSIS
    Deletes the workforce app registrations created by Configure.ps1 and restores placeholders.
#>

[CmdletBinding()]
param(
    [string] $TenantId,
    [string] $MauiAppName = "workforce-dotnet-blazor-maui",
    [string] $WebAppName = "workforce-dotnet-blazor-maui-web",
    [ValidateSet("Global", "AzureChinaCloud", "AzureUSGovernment")]
    [string] $AzureEnvironmentName = "Global"
)

$ErrorActionPreference = "Stop"
$ProjectDir = Resolve-Path (Join-Path $PSScriptRoot "..")

foreach ($module in @("Microsoft.Graph.Applications")) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Install-Module $module -Scope CurrentUser -Force
    }

    Import-Module $module
}

Connect-MgGraph `
    -TenantId $TenantId `
    -Scopes "Application.ReadWrite.All" `
    -Environment $AzureEnvironmentName `
    -NoWelcome

try {
    foreach ($appName in @($MauiAppName, $WebAppName)) {
        Get-MgApplication -Filter "displayName eq '$appName'" -All |
            ForEach-Object {
                Remove-MgApplication -ApplicationId $_.Id
                Write-Host "Deleted app registration '$appName' ($($_.AppId))."
            }
    }

    $mauiSettingsPath = Join-Path $ProjectDir "SignInBlazorMauiWorkforce" "appsettings.json"
    $mauiSettings = Get-Content $mauiSettingsPath -Raw | ConvertFrom-Json
    $mauiSettings.AzureAd.Authority = "https://login.microsoftonline.com/Enter_the_Tenant_Id_Here"
    $mauiSettings.AzureAd.ClientId = "Enter_the_Application_Id_Here"
    $mauiSettings.DownstreamApi.Scopes = @("api://Enter_the_Web_Application_Id_Here/access_as_user")
    $mauiSettings | ConvertTo-Json -Depth 10 | Set-Content $mauiSettingsPath -Encoding UTF8

    $webSettingsPath = Join-Path $ProjectDir "SignInBlazorMauiWorkforce.Web" "appsettings.json"
    $webSettings = Get-Content $webSettingsPath -Raw | ConvertFrom-Json
    $webSettings.AzureAd.Instance = "https://login.microsoftonline.com/"
    $webSettings.AzureAd.TenantId = "Enter_the_Tenant_Id_Here"
    $webSettings.AzureAd.ClientId = "Enter_the_Web_Application_Id_Here"
    $webSettings.AzureAd.ClientSecret = "Enter_the_Client_Secret_Here"
    $webSettings | ConvertTo-Json -Depth 10 | Set-Content $webSettingsPath -Encoding UTF8

    foreach ($platformFile in @(
        (Join-Path $ProjectDir "SignInBlazorMauiWorkforce" "Platforms" "Android" "AndroidManifest.xml"),
        (Join-Path $ProjectDir "SignInBlazorMauiWorkforce" "Platforms" "iOS" "Info.plist"),
        (Join-Path $ProjectDir "SignInBlazorMauiWorkforce" "Platforms" "MacCatalyst" "Info.plist")
    )) {
        (Get-Content $platformFile -Raw) `
            -replace "msal[a-f0-9-]+", "msalEnter_the_Application_Id_Here" |
            Set-Content $platformFile -Encoding UTF8
    }
}
finally {
    Disconnect-MgGraph | Out-Null
}
