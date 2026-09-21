---
page_type: sample
name: A .NET MAUI app using MSAL.NET with Microsoft Entra ID workforce tenants
description: Sign work or school users in to a native .NET MAUI app from one Microsoft Entra ID tenant.
languages:
 - csharp
products:
 - msalnet
 - entra-id
urlFragment: ms-identity-dotnet-tutorial-7-sign-in-maui-workforce
extensions:
    services:
    - ms-identity
    platform:
    - DotNet
    endpoint:
    - AAD v2.0
    level:
    - 100
    client:
    - MAUI App
---

# A .NET MAUI native app using MSAL.NET with Microsoft Entra ID

This sample signs work or school users from a single Microsoft Entra ID workforce tenant into a native .NET MAUI app. It uses MSAL.NET as a public client, retains the platform token-cache behavior from the native sample, and displays the acquired ID-token claims.

## Prerequisites

- [Visual Studio 2022 17.14+](https://aka.ms/vsdownload) or the [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) with the MAUI workload.
- A Microsoft Entra ID workforce tenant and a user account in that tenant.
- Permission to create an app registration, or an existing registration provided by your tenant administrator.

## Setup

Clone the repository, then open `1-Authentication/7-sign-in-maui-workforce/sign-in-maui-workforce.sln`.

### Register the app manually

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com/) for the workforce tenant.
1. Go to **App registrations** > **New registration**.
1. Enter a name such as `workforce-dotnet-maui`.
1. Under **Supported account types**, choose **Accounts in this organizational directory only**. This is the single-tenant `AzureADMyOrg` audience.
1. Select **Register**, then copy the **Application (client) ID** and **Directory (tenant) ID** from **Overview**.
1. In **Authentication**, add **Mobile and desktop applications**. Register both redirects:
   - `msal{ApplicationId}://auth`
   - `http://localhost`
1. Under **API permissions**, add the Microsoft Graph delegated **User.Read** permission. Grant admin consent if your organization requires it.

Do not create a client secret: this is a public native client.

### Configure the project

1. In `appsettings.json`, replace `Enter_the_Tenant_Id_Here` and `Enter_the_Application_Id_Here`. The authority must remain in this form:

   ```json
   "Authority": "https://login.microsoftonline.com/Enter_the_Tenant_Id_Here"
   ```

1. In `Platforms/Android/AndroidManifest.xml`, replace the application-ID placeholder in `msalEnter_the_Application_Id_Here`.
1. In `Platforms/iOS/Info.plist` and `Platforms/MacCatalyst/Info.plist`, replace it in `CFBundleURLSchemes`.

The Android, iOS, and Mac Catalyst redirects must exactly match `msal{ApplicationId}://auth`; Windows uses `http://localhost`.

### Use the registration script

Alternatively, [Configure.ps1](./AppCreationScripts/Configure.ps1) creates a matching single-tenant public client and updates the placeholders:

```pwsh
cd AppCreationScripts
./Configure.ps1 -TenantId "contoso.onmicrosoft.com"
```

See [AppCreationScripts.md](./AppCreationScripts/AppCreationScripts.md) for prerequisites, cloud options, and cleanup.

## Run the sample

Choose an Android, iOS, Mac Catalyst, or Windows target and run the app. Select **Sign In**, use a work or school account from the configured tenant, and review the ID-token claims. **Sign Out** removes MSAL accounts so a subsequent sign-in cannot silently reuse the signed-out account.

## How it works

- `MSALClient/MsalConfig.cs` loads the embedded `appsettings.json` resource using the `SignInMauiWorkforce` namespace.
- `MsalServiceExtensions.cs` configures a public client with the tenant authority and the platform redirect. It preserves native MSAL cache behavior, with SecureStorage-backed cache persistence on Windows and Mac Catalyst.
- `MsalTokenService.cs` first tries silent token acquisition and uses interactive sign-in only when required.
- The sample requests Microsoft Graph `User.Read`; MSAL also obtains the OpenID Connect tokens needed to show identity claims.

## Troubleshooting

- Verify that the app registration audience is **Accounts in this organizational directory only** and that the tenant ID in the authority is the same tenant.
- Verify every registered redirect exactly matches the platform configuration, including the `msal` prefix and `auth` host.
- If your tenant requires consent, ask an administrator to grant consent for `User.Read`.
- Ensure the .NET MAUI workload is installed if the project does not load or build.

## Learn more

- [Microsoft identity platform and OAuth 2.0](https://learn.microsoft.com/entra/identity-platform/v2-oauth2-auth-code-flow)
- [MSAL.NET](https://learn.microsoft.com/entra/msal/dotnet/)
- [Microsoft Entra app registration](https://learn.microsoft.com/entra/identity-platform/quickstart-register-app)
