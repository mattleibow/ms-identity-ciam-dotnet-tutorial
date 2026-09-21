---
title: "Quickstart: Run a .NET MAUI workforce app"
description: Learn how to sign work or school users in and out with a .NET MAUI app and Microsoft Entra ID.
author: Microsoft
ms.service: entra-id
ms.custom: devx-track-dotnet
ROBOTS: NOINDEX
ms.topic: conceptual
---

# Portal quickstart for .NET MAUI and Microsoft Entra ID

This quickstart runs a native .NET MAUI app that signs in users from one Microsoft Entra ID workforce tenant.

1. Install the [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) and the MAUI workload.
1. Open `1-Authentication/7-sign-in-maui-workforce/sign-in-maui-workforce.sln`.
1. Register the single-tenant public client as described in the [README](../README.md), then configure its tenant ID and application ID.
1. Select a Windows, Android, iOS, or Mac Catalyst target and run the app.

The app uses `msal{ApplicationId}://auth` on mobile Apple and Android targets and `http://localhost` on Windows.
