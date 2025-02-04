using VeroScripts.Base;

namespace VeroScripts.ViewModels;

public class SettingsViewModel : NotifyPropertyChanged
{
    private bool _includeSpace = UserSettings.Get(nameof(IncludeSpace), false);
    public bool IncludeSpace
    {
        get => _includeSpace;
        set
        {
            if (Set(ref _includeSpace, value))
            {
                UserSettings.Store(nameof(IncludeSpace), _includeSpace);
                UserSettings.OnPropertyChanged();
            }
        }
    }
}
