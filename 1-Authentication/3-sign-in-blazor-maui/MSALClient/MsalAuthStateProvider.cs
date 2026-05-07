// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.Identity.Client;
using System.Security.Claims;

namespace SignInBlazorMaui.MSALClient;

/// <summary>
/// Blazor <see cref="AuthenticationStateProvider"/> that uses <see cref="MsalTokenService"/>
/// to authenticate against Microsoft Entra External ID (CIAM).
/// Handles silent token acquisition on startup and notifies Blazor on state changes.
/// </summary>
public class MsalAuthStateProvider(MsalTokenService msalTokenService) : AuthenticationStateProvider
{
    private static readonly ClaimsPrincipal _anonymous = new(new ClaimsIdentity());
    private ClaimsPrincipal _currentUser = _anonymous;
    private bool _initialized;

    public override async Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        if (!_initialized)
        {
            _initialized = true;
            await TrySignInSilentAsync();
        }

        return new AuthenticationState(_currentUser);
    }

    /// <summary>
    /// Attempts silent sign-in using cached accounts.
    /// Returns true if a valid cached token was found.
    /// </summary>
    public async Task<bool> TrySignInSilentAsync()
    {
        var account = await msalTokenService.GetAccountAsync();
        if (account is null)
            return false;

        try
        {
            var result = await msalTokenService.SignInAsync();
            SetCurrentUser(result);
            return true;
        }
        catch (MsalUiRequiredException)
        {
            // No cached token — user must sign in interactively
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Silent sign-in failed: {ex.Message}");
        }

        return false;
    }

    /// <summary>
    /// Launches an interactive sign-in flow and notifies Blazor on success.
    /// </summary>
    public async Task SignInInteractiveAsync()
    {
        try
        {
            var result = await msalTokenService.SignInInteractiveAsync();
            SetCurrentUser(result);
        }
        catch (MsalClientException ex) when (ex.ErrorCode == "authentication_canceled")
        {
            Console.WriteLine("User canceled authentication.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Sign-in error: {ex.GetType().Name}: {ex.Message}");
        }
    }

    /// <summary>
    /// Signs out the current user and notifies Blazor.
    /// </summary>
    public async Task SignOutAsync()
    {
        await msalTokenService.SignOutAsync();
        _currentUser = _anonymous;
        NotifyAuthenticationStateChanged(Task.FromResult(new AuthenticationState(_anonymous)));
    }

    private void SetCurrentUser(AuthenticationResult result)
    {
        List<Claim> claims =
        [
            new(ClaimTypes.Name, result.Account.Username ?? "User"),
        ];

        if (result.ClaimsPrincipal?.Claims is not null)
        {
            foreach (var claim in result.ClaimsPrincipal.Claims)
            {
                if (!claims.Any(c => c.Type == claim.Type))
                    claims.Add(claim);
            }
        }

        _currentUser = new ClaimsPrincipal(new ClaimsIdentity(claims, "Entra External ID"));
        NotifyAuthenticationStateChanged(Task.FromResult(new AuthenticationState(_currentUser)));
    }
}
