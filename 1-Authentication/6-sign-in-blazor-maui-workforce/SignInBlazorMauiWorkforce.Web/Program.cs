using SignInBlazorMauiWorkforce.Shared.Services;
using SignInBlazorMauiWorkforce.Web.Components;
using SignInBlazorMauiWorkforce.Web.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.Identity.Web;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents()
    .AddInteractiveWebAssemblyComponents()
    // Serialize the server-side authentication state so it flows to WebAssembly
    // components without the browser needing to hold any tokens. SerializeAllClaims
    // makes the full set available to the WebAssembly Account page.
    .AddAuthenticationStateSerialization(options => options.SerializeAllClaims = true);

// Add device-specific services used by the SignInBlazorMauiWorkforce.Shared project
builder.Services.AddSingleton<IFormFactor, FormFactor>();
builder.Services.AddScoped<IWeatherService, WeatherService>();

builder.Services.AddCascadingAuthenticationState();

// Dual authentication: OIDC + Cookie for web browser, JWT Bearer for MAUI API calls.
// A policy scheme routes requests to the correct handler based on the Authorization header.
var authBuilder = builder.Services.AddAuthentication(options =>
    {
        options.DefaultScheme = "BearerOrCookie";
        options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
    })
    .AddPolicyScheme("BearerOrCookie", "Bearer or Cookie", options =>
    {
        options.ForwardDefaultSelector = context =>
        {
            var authHeader = context.Request.Headers.Authorization.FirstOrDefault();
            if (authHeader?.StartsWith("Bearer ") == true)
                return JwtBearerDefaults.AuthenticationScheme;
            return CookieAuthenticationDefaults.AuthenticationScheme;
        };
    });

// OpenID Connect + Cookie for web browser users
authBuilder.AddMicrosoftIdentityWebApp(builder.Configuration.GetSection("AzureAd"));

// Handle authentication failures gracefully (for example, if the user cancels sign-in).
builder.Services.Configure<OpenIdConnectOptions>(OpenIdConnectDefaults.AuthenticationScheme, options =>
{
    options.Events ??= new OpenIdConnectEvents();
    options.Events.OnRemoteFailure = context =>
    {
        // Log the real reason so authentication failures aren't silently swallowed.
        var logger = context.HttpContext.RequestServices
            .GetRequiredService<ILoggerFactory>()
            .CreateLogger("OidcRemoteFailure");
        logger.LogError(context.Failure, "OIDC remote failure: {Message}", context.Failure?.Message);

        context.Response.Redirect("/");
        context.HandleResponse();
        return Task.CompletedTask;
    };
});

// JWT Bearer validation for MAUI client API calls
authBuilder.AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"),
    jwtBearerScheme: JwtBearerDefaults.AuthenticationScheme);

builder.Services.AddAuthorization();

// For more information on OpenAPI support in ASP.NET Core,
// see OpenAPI support in ASP.NET Core API apps at
// https://learn.microsoft.com/aspnet/core/fundamentals/openapi/overview
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}
else
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);
app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.UseAntiforgery();

app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode()
    .AddInteractiveWebAssemblyRenderMode()
    .AddAdditionalAssemblies(
        typeof(SignInBlazorMauiWorkforce.Shared._Imports).Assembly,
        typeof(SignInBlazorMauiWorkforce.Web.Client._Imports).Assembly);

// Login endpoint: triggers the Microsoft Entra ID OIDC redirect.
app.MapGet("/authentication/login", async (HttpContext context, string? returnUrl) =>
{
    await context.ChallengeAsync(OpenIdConnectDefaults.AuthenticationScheme,
        new AuthenticationProperties { RedirectUri = returnUrl ?? "/" });
});

// Logout endpoint: clears cookie and signs out of Entra
app.MapPost("/authentication/logout", async (HttpContext context) =>
{
    await context.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
    await context.SignOutAsync(OpenIdConnectDefaults.AuthenticationScheme,
        new AuthenticationProperties { RedirectUri = "/" });
});

// Add the weather API endpoint and require authorization
app.MapGet("/api/weather", async (IWeatherService weatherService) =>
{
    var forecasts = await weatherService.GetWeatherForecastsAsync();
    return TypedResults.Ok(forecasts);
}).RequireAuthorization();

app.Run();
