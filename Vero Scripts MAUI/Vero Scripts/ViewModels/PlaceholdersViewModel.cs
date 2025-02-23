using System.Collections.ObjectModel;
using System.ComponentModel;
using VeroScripts.Base;
using VeroScripts.Models;

namespace VeroScripts.ViewModels;

public sealed class PlaceholdersViewModel : NotifyPropertyChanged
{
    public PlaceholdersViewModel(FeatureViewModel viewModel, Script script)
    {
        ViewModel = viewModel;
        _script = script;
        Placeholders = viewModel.PlaceholdersMap[script];
        LongPlaceholders = viewModel.LongPlaceholdersMap[script];
        foreach (var placeholder in Placeholders)
        {
            placeholder.PropertyChanged += PlaceholderOnPropertyChanged;
        }
        OnPropertyChanged(nameof(ScriptLength));
    }

    private readonly Script _script;

    private void PlaceholderOnPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        OnPropertyChanged(nameof(ScriptLength));
    }

    public FeatureViewModel ViewModel { get; }
    
    public int ScriptLength => ViewModel.ProcessPlaceholders(_script).Length;

    public ObservableCollection<Placeholder> Placeholders { get; }
    
    public ObservableCollection<Placeholder> LongPlaceholders { get; }
}
