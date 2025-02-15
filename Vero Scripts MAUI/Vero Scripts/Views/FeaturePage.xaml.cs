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

    private void AdjustForKeyboard(bool isKeyboardVisible)
    {
        // Adjust the padding to reserve space for the keyboard
        if (isKeyboardVisible)
        {
            var keyboardHeight = GetKeyboardHeight();
            MainScrollView.Padding = new Thickness(0, 0, 0, keyboardHeight);
        }
        else
        {
            MainScrollView.Padding = new Thickness(0);
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
