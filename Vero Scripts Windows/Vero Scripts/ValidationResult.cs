namespace VeroScripts
{
    public enum ValidationResultType
    {
        Valid,
        Warning,
        Error
    }

    public struct ValidationResult(ValidationResultType type, string? error = null)
    {
        public ValidationResultType Type { get; private set; } = type;

        public readonly bool IsValid => Type == ValidationResultType.Valid;

        public readonly bool IsWarning => Type == ValidationResultType.Warning;

        public readonly bool IsError => Type == ValidationResultType.Error;

        public string? Error { get; private set; } = error;

        public static bool operator ==(ValidationResult x, ValidationResult y)
        {
            return x.Type == y.Type && x.Error == y.Error;
        }

        public static bool operator !=(ValidationResult x, ValidationResult y)
        {
            return !(x == y);
        }

        public override readonly bool Equals(object? obj)
        {
            if (obj is ValidationResult)
            {
                var objAsValidationResult = obj as ValidationResult?;
                return this == objAsValidationResult;
            }
            return false;
        }

        public override readonly int GetHashCode()
        {
            return Type.GetHashCode() + (Error ?? "").GetHashCode();
        }
    }
}
