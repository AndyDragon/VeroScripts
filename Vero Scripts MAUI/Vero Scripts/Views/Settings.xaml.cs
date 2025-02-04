using VeroScripts.ViewModels;

namespace VeroScripts.Views;

public partial class Settings
{
    public Settings()
    {
        InitializeComponent();
        BindingContext = new SettingsViewModel();
    }
}
