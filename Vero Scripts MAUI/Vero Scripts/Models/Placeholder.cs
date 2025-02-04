using VeroScripts.Base;

namespace VeroScripts.Models;

// TODO andydragon - need to review if the property change monitoring is needed?
public class Placeholder : NotifyPropertyChanged
{
    public Placeholder(string name, string value)
    {
        Name = name;
        Value = value;
    }

    private readonly string name = "";
    public string Name
    {
        get => name;
        private init => Set(ref name, value);
    }

    private string currentValue = "";
    public string Value
    {
        get => currentValue;
        set => Set(ref currentValue, value);
    }
}
