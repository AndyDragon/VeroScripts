using ControlzEx.Theming;
using System.Globalization;
using System.Windows;
using System.Windows.Data;
using System.Windows.Media;

namespace VeroScripts
{
    class ValidationResultBrushConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var brushName = "MahApps.Brushes.Text";
            var defaultBrush = SystemColors.ControlTextBrush;
            if (value is ValidationResult validationResult)
            {
                switch (validationResult.Type)
                {
                    case ValidationResultType.Error:
                        brushName = "MahApps.Brushes.Control.Validation";
                        defaultBrush = new SolidColorBrush(Colors.Red);
                        break;

                    case ValidationResultType.Warning:
                        brushName = "MahApps.Brushes.Control.Warning";
                        defaultBrush = new SolidColorBrush(Colors.Orange);
                        break;
                }
            }
            return (ThemeManager.Current.DetectTheme(Application.Current)?.Resources[brushName] as Brush) ?? defaultBrush;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class ValidationResultColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var colorName = "MahApps.Colors.Text";
            var defaultColor = SystemColors.ControlTextColor;
            if (value is ValidationResult validationResult)
            {
                switch (validationResult.Type)
                {
                    case ValidationResultType.Error:
                        colorName = "MahApps.Colors.Control.Validation";
                        defaultColor = Colors.Red;
                        break;

                    case ValidationResultType.Warning:
                        colorName = "MahApps.Colors.Control.Warning";
                        defaultColor = Colors.Orange;
                        break;
                }
            }
            return (ThemeManager.Current.DetectTheme(Application.Current)?.Resources[colorName] as Color?) ?? defaultColor;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class ValidationResultVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is ValidationResult validationResult && !validationResult.IsValid)
            {
                return Visibility.Visible;
            }
            return Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class ValidationBooleanColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var result = (value as Boolean?) ?? false;
            var brushName = "MahApps.Brushes.Text";
            var defaultBrush = SystemColors.ControlTextBrush;
            if (!result)
            {
                brushName = "MahApps.Brushes.Control.Validation";
                defaultBrush = new SolidColorBrush(Colors.Red);
            }
            return (ThemeManager.Current.DetectTheme(Application.Current)?.Resources[brushName] as Brush) ?? defaultBrush;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class ValidationBooleanVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var result = (value as Boolean?) ?? false;
            if (!result)
            {
                return Visibility.Visible;
            }
            return Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
