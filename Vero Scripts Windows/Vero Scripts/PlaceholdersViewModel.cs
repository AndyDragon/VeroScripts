using System.Collections.ObjectModel;

namespace VeroScripts
{
    public partial class PlaceholdersViewModel(MainViewModel scriptViewModel, Script script)
    {
        public MainViewModel ScriptsViewModel { get; private set; } = scriptViewModel;

        public ObservableCollection<Placeholder> Placeholders { get; private set; } = scriptViewModel.PlaceholdersMap[script];
        public ObservableCollection<Placeholder> LongPlaceholders { get; private set; } = scriptViewModel.LongPlaceholdersMap[script];
    }
}
