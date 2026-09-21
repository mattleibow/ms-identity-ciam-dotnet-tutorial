# App registration scripts

`Configure.ps1` creates the two Microsoft Entra ID workforce app registrations required by this sample. It uses Microsoft Graph PowerShell and creates only single-tenant (`AzureADMyOrg`) applications.

## Configure

Install PowerShell 7, then run:

```powershell
cd AppCreationScripts
./Configure.ps1 -TenantId "contoso.onmicrosoft.com"
```

The script installs the Microsoft Graph PowerShell modules for the current user when necessary, then requests `Application.ReadWrite.All` and `Organization.Read.All`. It creates or reuses the registrations, creates the sample API delegated scope, and changes the placeholder configuration in this sample only.

Use `-MauiAppName` and `-WebAppName` to use different display names. For Azure China or Azure US Government, pass `-AzureEnvironmentName AzureChinaCloud` or `-AzureEnvironmentName AzureUSGovernment`.

## Cleanup

To delete registrations with the default display names and restore placeholders:

```powershell
./Cleanup.ps1 -TenantId "contoso.onmicrosoft.com"
```

Cleanup deletes every registration with the supplied display names in the connected tenant. Use custom names when you need to preserve another registration.
