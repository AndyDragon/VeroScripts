using System.Reflection;

namespace VeroScriptsEditor
{
    public class AboutViewModel
    {
        public string Title => "About VERO Scripts Editor";
        public string AppTitle => "VERO Scripts Editor";
        public string Version => $"Version {Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "---"}";
        public string Author => $"AndyDragon Software";
        public string Copyright => $"Copyright \u00a9 2024-{DateTime.Now.Year}";
        public string Rights => $"All rights reserved.";
    }
}
