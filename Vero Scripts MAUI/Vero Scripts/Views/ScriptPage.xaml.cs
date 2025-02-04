using VeroScripts.Base;
using VeroScripts.ViewModels;

namespace VeroScripts.Views;

public partial class ScriptPage
{
    public ScriptPage(ScriptViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
