using VeroScripts.Base;

namespace VeroScripts.ViewModels;

public class SettingsViewModel : NotifyPropertyChanged
{
    private bool _includeSpace = Preferences.Default.Get(nameof(IncludeSpace), false);
    public bool IncludeSpace
    {
        get => _includeSpace;
        set
        {
            if (Set(ref _includeSpace, value))
            {
                Preferences.Default.Set(nameof(IncludeSpace), value);
                UserSettings.OnPropertyChanged();
            }
        }
    }
}
