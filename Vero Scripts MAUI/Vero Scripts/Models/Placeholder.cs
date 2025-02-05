using VeroScripts.Base;

namespace VeroScripts.Models;

public class Placeholder : NotifyPropertyChanged
{
    public Placeholder(string name, string value)
    {
        Name = name;
        Value = value;
    }

    private readonly string _name = "";
    public string Name
    {
        get => _name;
        private init => Set(ref _name, value);
    }

    private string _currentValue = "";
    public string Value
    {
        get => _currentValue;
        set => Set(ref _currentValue, value);
    }
}
