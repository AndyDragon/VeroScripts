using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace VeroScriptsEditor
{
    public abstract class NotifyPropertyChanged : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler? PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        public bool Set<T>(ref T storage, T value, string[]? associatedPropertyNames = null, [CallerMemberName()] string? propertyName = null)
        {
            if (!object.Equals(storage, value))
            {
                storage = value;
                OnPropertyChanged(propertyName);
                if (associatedPropertyNames != null)
                {
                    foreach (var associatedProperty in associatedPropertyNames)
                    {
                        OnPropertyChanged(associatedProperty);
                    }
                }
                return true;
            }
            return false;
        }

        public bool SetWithDirtyCallback<T>(ref T storage, T value, Action setDirty, string[]? associatedPropertyNames = null, [CallerMemberName()] string? propertyName = null)
        {
            if (!object.Equals(storage, value))
            {
                storage = value;
                OnPropertyChanged(propertyName);
                if (associatedPropertyNames != null)
                {
                    foreach (var associatedProperty in associatedPropertyNames)
                    {
                        OnPropertyChanged(associatedProperty);
                    }
                }
                setDirty();
                return true;
            }
            return false;
        }

        public bool SetWithCommands<T>(ref T storage, T value, Command[]? commands = null, [CallerMemberName()] string? propertyName = null)
        {
            if (!object.Equals(storage, value))
            {
                storage = value;
                OnPropertyChanged(propertyName);
                if (commands != null)
                {
                    foreach (var command in commands)
                    {
                        command.OnCanExecuteChanged();
                    }
                }
                return true;
            }
            return false;
        }

        public bool SetWithCommandsWithParameter<T>(ref T storage, T value, CommandWithParameter[]? commands = null, [CallerMemberName()] string? propertyName = null)
        {
            if (!object.Equals(storage, value))
            {
                storage = value;
                OnPropertyChanged(propertyName);
                if (commands != null)
                {
                    foreach (var command in commands)
                    {
                        command.OnCanExecuteChanged();
                    }
                }
                return true;
            }
            return false;
        }
    }
}
