using System;
using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;

namespace Vero_Scripts
{
    class ValidateEmptyConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            // If the value is empty, fail validation.
            if (string.IsNullOrEmpty((value ?? "").ToString()))
            {
                return new SolidColorBrush(Colors.Red);
            }
            return FramePFX.Themes.ThemesController.GetBrush("ControlDefaultForeground");
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class ValidateNotEqualConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            // If the value is empty OR it is the default, fail validation.
            if (string.IsNullOrEmpty((value ?? "").ToString()) 
                || string.Equals((value ?? "").ToString(), (parameter ?? "").ToString()))
            {
                return new SolidColorBrush(Colors.Red);
            }
            return FramePFX.Themes.ThemesController.GetBrush("ControlDefaultForeground");
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class ValidateNotEqualAndNotEmptyConverter : IMultiValueConverter
    {
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values.Length == 2)
            {
                // If the first value is empty OR it is the default AND the second value is empty, fail validation.
                if ((string.IsNullOrEmpty((values[0] ?? "").ToString()) 
                    || string.Equals((values[0] ?? "").ToString(), (parameter ?? "").ToString()))
                    && string.IsNullOrEmpty((values[1] ?? "").ToString()))
                {
                    return new SolidColorBrush(Colors.Red);
                }
            }
            return FramePFX.Themes.ThemesController.GetBrush("ControlDefaultForeground");
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
