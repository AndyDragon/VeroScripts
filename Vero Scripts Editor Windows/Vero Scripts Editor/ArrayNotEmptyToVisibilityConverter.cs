using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace VeroScriptsEditor
{
    public class ArrayNotEmptyToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value != null && value.GetType().IsArray)
            {
                var property = value.GetType().GetProperty(nameof(Array.Length));
                if (property != null)
                {
                    var lengthValue = property.GetValue(value);
                    if (lengthValue != null)
                    {
                        return ((int)lengthValue) != 0 ? Visibility.Visible : Visibility.Collapsed;
                    }
                }
            }
            return Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
