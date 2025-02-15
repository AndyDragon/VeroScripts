using VeroScripts.Base;
using VeroScripts.ViewModels;

namespace VeroScripts.Views;

public partial class NewMembershipPage
{
    public NewMembershipPage(FeatureViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
#if ANDROID
        KeyboardHelper.Initialize(Platform.CurrentActivity);
        KeyboardHelper.KeyboardVisibilityChanged += OnKeyboardVisibilityChanged;
#endif
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
