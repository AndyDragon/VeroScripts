using System.Collections.ObjectModel;
using VeroScripts.Models;

namespace VeroScripts.ViewModels;

public class PlaceholdersViewModel(FeatureViewModel viewModel, Script script)
{
    public FeatureViewModel ViewModel { get; private set; } = viewModel;

    public ObservableCollection<Placeholder> Placeholders { get; private set; } = viewModel.PlaceholdersMap[script];
    
    public ObservableCollection<Placeholder> LongPlaceholders { get; private set; } = viewModel.LongPlaceholdersMap[script];
}
