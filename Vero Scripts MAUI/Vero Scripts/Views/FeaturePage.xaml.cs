using VeroScripts.ViewModels;
using MauiIcons.Core;

namespace VeroScripts.Views;

public partial class FeaturePage
{
    public FeaturePage()
    {
        InitializeComponent();
        // Temporary Workaround for url styled namespace in xaml
        _ = new MauiIcon();
        BindingContext = new FeatureViewModel();
    }
}
