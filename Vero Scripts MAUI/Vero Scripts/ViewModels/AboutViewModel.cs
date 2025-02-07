using System.Reflection;

namespace VeroScripts.ViewModels;

public class AboutViewModel
{
    public string Title => "About Vero Scripts";
    public string AppTitle => "Vero Scripts";
    public string Version => $"Version {Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "---"}";
    public string Author => $"AndyDragon Software";
    public string Copyright => $"Copyright \u00a9 2024-{DateTime.Now.Year}";
    public string Rights => $"All rights reserved.";
}
