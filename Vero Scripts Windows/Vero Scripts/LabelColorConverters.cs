using System;
using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;
using FramePFX.Themes;

namespace Vero_Scripts
{
    class ValidationResultLabelConverter : IMultiValueConverter
    {
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values.Length > 0)
            {
                var validationResult = values[0] as ValidationResult?;
                if (validationResult == null || !(validationResult?.Valid ?? false))
                {
                    return new SolidColorBrush(Colors.Red);
                }
            }
            return ThemesController.GetBrush("ABrush.Foreground.Static");
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class BooleanLabelConverter : IMultiValueConverter
    {
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values.Length > 0)
            {
                var result = (values[0] as Boolean?) ?? false;
                if (!result)
                {
                    return new SolidColorBrush(Colors.Red);
                }
            }
            return ThemesController.GetBrush("ABrush.Foreground.Static");
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
