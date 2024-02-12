using System;
using System.Collections.ObjectModel;
using System.ComponentModel;

namespace Vero_Scripts
{
    public partial class PlaceholdersViewModel
    {
        public PlaceholdersViewModel(ScriptsViewModel scriptViewModel, Script script) 
        {
            ScriptsViewModel = scriptViewModel;
            Placeholders = scriptViewModel.PlaceholdersMap[script];
        }

        public ScriptsViewModel ScriptsViewModel { get; private set; }

        public ObservableCollection<Placeholder> Placeholders { get; private set; }
    }
}
