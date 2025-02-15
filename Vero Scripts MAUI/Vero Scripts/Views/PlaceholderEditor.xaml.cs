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
#if ANDROID
        KeyboardHelper.Initialize(Platform.CurrentActivity);
        KeyboardHelper.KeyboardVisibilityChanged += OnKeyboardVisibilityChanged;
#endif
    }

    private void OnCopyClicked(object sender, EventArgs e)
    {
        if (BindingContext is PlaceholdersViewModel viewModel)
        {
            viewModel.ViewModel.CopyScriptFromPlaceholders(_script);
            Application.Current?.Windows[0].Page?.Navigation.PopAsync();
        }
    }

    private void OnCopyUnchangedClicked(object sender, EventArgs e)
    {
        if (BindingContext is PlaceholdersViewModel viewModel)
        {
            viewModel.ViewModel.CopyScriptFromPlaceholders(_script, withPlaceholders: true);
            Application.Current?.Windows[0].Page?.Navigation.PopAsync();
        }
    }

    private void OnCancelClicked(object sender, EventArgs e)
    {
        Application.Current?.Windows[0].Page?.Navigation.PopAsync();
    }
    
#if ANDROID
    protected override void OnAppearing()
    {
        base.OnAppearing();
        AdjustForKeyboard(KeyboardHelper.IsKeyboardVisible);
    }

    private void OnKeyboardVisibilityChanged(object? sender, bool isVisible)
    {
        AdjustForKeyboard(isVisible);
    }

    private void AdjustForKeyboard(bool isVisible)
    {
        // Adjust the padding to reserve space for the keyboard
        if (isVisible)
        {
            var keyboardHeight = GetKeyboardHeight();
            MainGrid.Margin = new Thickness(20, 20, 20, 20 + keyboardHeight);
        }
        else
        {
            MainGrid.Margin = new Thickness(20);
        }
    }

    private static double GetKeyboardHeight()
    {
        var rootView = Platform.CurrentActivity?.Window?.DecorView.RootView;
        var rect = new Android.Graphics.Rect();
        if (rootView != null)
        {
            rootView.GetWindowVisibleDisplayFrame(rect);
            var screenHeight = rootView.Height;
            var keypadHeight = screenHeight - rect.Bottom;
            return KeyboardHelper.ConvertPixelsToDp(keypadHeight);
        }

        return 0;
    }
#endif
}
