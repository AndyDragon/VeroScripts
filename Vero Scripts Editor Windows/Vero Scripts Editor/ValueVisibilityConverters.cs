using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace VeroScriptsEditor
{
    public class ValueVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var positiveValue = System.Convert.ToBoolean(parameter);
            if (value is string stringValue)
            {
                return string.IsNullOrEmpty(stringValue) != positiveValue ? Visibility.Visible : Visibility.Collapsed;
            }
            return Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class NullVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var positiveValue = System.Convert.ToBoolean(parameter);
            return ((value != null) != positiveValue) ? Visibility.Visible : Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
