using System.Collections.ObjectModel;

namespace VeroScriptsEditor
{
    public partial class PlaceholdersViewModel(MainViewModel viewModel)
    {
        public MainViewModel ViewModel { get; private set; } = viewModel;

        public ObservableCollection<Placeholder> Placeholders { get; private set; } = viewModel.PlaceholdersMap;
        public ObservableCollection<Placeholder> LongPlaceholders { get; private set; } = viewModel.LongPlaceholdersMap;
    }
}
