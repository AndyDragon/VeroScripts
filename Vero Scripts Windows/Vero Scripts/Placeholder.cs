using System;
using System.ComponentModel;

namespace Vero_Scripts
{
    public class Placeholder : INotifyPropertyChanged
    {
        public Placeholder(string name)
        {
            Name = name;
        }

        public Placeholder(string name, string value)
        {
            Name = name;
            Value = value;
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        private string name = "";
        public string Name
        {
            get { return name; }
            set
            {
                if (value != name)
                {
                    name = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Name)));
                }
            }
        }

        private string value = "";
        public string Value
        {
            get { return value; }
            set
            {
                if (value != this.value)
                {
                    this.value = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Value)));
                }
            }
        }
    }
}
