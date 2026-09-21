using Android.App;
using Microsoft.Identity.Client;

namespace SignInBlazorMauiWorkforce.Platforms.Android;

/// <summary>
/// Activity that handles the MSAL redirect URI callback from the system browser
/// after Microsoft Entra ID authentication completes.
/// The intent filter is declared in AndroidManifest.xml so that scripts can
/// replace the placeholder client ID.
/// </summary>
[Activity(Exported = true, Name = "com.companyname.signinblazormauiworkforce.MsalActivity")]
public class MsalActivity : BrowserTabActivity
{
}
