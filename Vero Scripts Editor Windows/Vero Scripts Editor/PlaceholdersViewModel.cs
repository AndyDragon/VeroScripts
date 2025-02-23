using System.Collections.ObjectModel;
using System.ComponentModel;

namespace VeroScriptsEditor
{
    public partial class PlaceholdersViewModel : NotifyPropertyChanged
    {
        public PlaceholdersViewModel(MainViewModel viewModel)
        {
            ViewModel = viewModel;
            Placeholders = viewModel.PlaceholdersMap;
            LongPlaceholders = viewModel.LongPlaceholdersMap;
            ScriptLength = ViewModel.ProcessPlaceholders().Length;

            foreach (var placeholder in Placeholders)
            {
                placeholder.PropertyChanged += OnPlaceholderPropertyChanged;
            }
            foreach (var placeholder in LongPlaceholders)
            {
                placeholder.PropertyChanged += OnPlaceholderPropertyChanged;
            }
        }

        private void OnPlaceholderPropertyChanged(object? sender, PropertyChangedEventArgs e)
        {
            ScriptLength = ViewModel.ProcessPlaceholders().Length;
        }

        public MainViewModel ViewModel { get; private set; }

        public ObservableCollection<Placeholder> Placeholders { get; private set; }
        public ObservableCollection<Placeholder> LongPlaceholders { get; private set; }

        private int scriptLength = 0;
        public int ScriptLength
        {
            get => scriptLength;
            set => Set(ref scriptLength, value);
        }
    }
}
