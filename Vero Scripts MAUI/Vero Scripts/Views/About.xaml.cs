using VeroScripts.ViewModels;

namespace VeroScripts.Views;

public partial class About
{
    public About()
    {
        InitializeComponent();
        BindingContext = new AboutViewModel();
    }
}
