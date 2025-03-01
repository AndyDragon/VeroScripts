using Android.App;

namespace VeroScripts;

public static class KeyboardHelper
{
    public static event EventHandler<bool>? KeyboardVisibilityChanged;

    public static void Initialize(Activity? activity)
    {
        var rootView = activity?.Window?.DecorView.RootView;
        if (rootView is { ViewTreeObserver: not null })
        {
            rootView.ViewTreeObserver.GlobalLayout += (_, _) =>
            {
                var rect = new Android.Graphics.Rect();
                rootView.GetWindowVisibleDisplayFrame(rect);
                var screenHeight = rootView.Height;
                var keypadHeight = screenHeight - rect.Bottom;

                var isVisible = keypadHeight > screenHeight * 0.15; // 15% threshold for keyboard visibility
                if (IsKeyboardVisible != isVisible)
                {
                    IsKeyboardVisible = isVisible;
                    KeyboardVisibilityChanged?.Invoke(null, isVisible);
                }
            };
        }
    }
    
    public static bool IsKeyboardVisible { get; private set; }

    public static double ConvertPixelsToDp(float pixelValue)
    {
        var metrics = Platform.CurrentActivity?.Resources?.DisplayMetrics;
        if (metrics is null)
        {
            return pixelValue;
        }
        return pixelValue / ((float)metrics.DensityDpi / 160f);
    }
}
