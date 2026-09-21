# Registering the workforce sample with PowerShell

`Configure.ps1` creates a single-tenant Microsoft Entra ID public client named `workforce-dotnet-maui`. It sets `AzureADMyOrg`, adds Microsoft Graph delegated `User.Read`, registers `msal{AppId}://auth` and `http://localhost`, and patches only this sample's configuration placeholders. To update an existing registration, pass its exact client ID with `-AppId`.

## Prerequisites

- PowerShell 7 or later.
- Permission to create app registrations in the target workforce tenant.
- The Microsoft Graph PowerShell modules. The script installs `Microsoft.Graph.Applications` and `Microsoft.Graph.Identity.DirectoryManagement` for the current user when needed.

## Configure

Run from this directory:

```pwsh
./Configure.ps1 -TenantId "contoso.onmicrosoft.com"
```

`-TenantId` can be omitted to use the tenant selected during Microsoft Graph sign-in. To select a sovereign cloud, pass `-AzureEnvironmentName AzureUSGovernment` or `AzureChinaCloud`.

To update an existing registration without locating it by its non-unique display name:

```pwsh
./Configure.ps1 -TenantId "contoso.onmicrosoft.com" -AppId "your-application-client-id"
```

## Cleanup

The cleanup script requires the exact client ID of the registration to delete and returns `appsettings.json` and the Android, iOS, and Mac Catalyst callback schemes to safe placeholders:

```pwsh
./Cleanup.ps1 -TenantId "contoso.onmicrosoft.com" -AppId "your-application-client-id"
```

Using the client ID prevents cleanup from affecting a different registration that happens to use the same display name.
