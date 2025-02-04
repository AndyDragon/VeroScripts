using VeroScripts.ViewModels;

namespace VeroScripts.Views;

public partial class PlaceholderEditor
{
    private readonly Script _script;
    
    public PlaceholderEditor(FeatureViewModel viewModel, Script script)
    {
        InitializeComponent();
        BindingContext = new PlaceholdersViewModel(viewModel, script);
        _script = script;
    }

    private void OnCopyClicked(object sender, EventArgs e)
    {
        if (BindingContext is PlaceholdersViewModel viewModel)
        {
            viewModel.ViewModel.CopyScriptFromPlaceholders(_script);
            Application.Current?.Windows[0].Navigation.PopAsync();
        }
    }

    private void OnCopyUnchangedClicked(object sender, EventArgs e)
    {
        if (BindingContext is PlaceholdersViewModel viewModel)
        {
            viewModel.ViewModel.CopyScriptFromPlaceholders(_script, withPlaceholders: true);
            Application.Current?.Windows[0].Navigation.PopAsync();
        }
    }

    private void OnCancelClicked(object sender, EventArgs e)
    {
        Application.Current?.Windows[0].Navigation.PopAsync();
    }
}
