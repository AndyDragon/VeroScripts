using VeroScripts.Base;
using VeroScripts.ViewModels;

namespace VeroScripts.Views;

public partial class NewMembershipPage
{
    public NewMembershipPage(FeatureViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
