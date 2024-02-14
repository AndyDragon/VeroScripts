using System;

namespace Vero_Scripts
{
    public struct ValidationResult
    {
        public ValidationResult(bool valid, string? error = null)
        {
            Valid = valid;
            Error = error;
        }

        public bool Valid { get; private set; }

        public string? Error { get; private set; }

        public static bool operator ==(ValidationResult x, ValidationResult y)
        {
            var xPrime = x;
            var yPrime = y;
            if (xPrime.Valid && yPrime.Valid)
            {
                return true;
            }
            if (xPrime.Valid || yPrime.Valid)
            {
                return false;
            }
            return xPrime.Error == yPrime.Error;
        }

        public static bool operator !=(ValidationResult x, ValidationResult y)
        {
            return !(x == y);
        }

        public override bool Equals(object? obj)
        {
            if (obj is ValidationResult)
            {
                var objAsValidationResult = obj as ValidationResult?;
                return this == objAsValidationResult;
            }
            return false;
        }

        public override int GetHashCode()
        {
            return Valid.GetHashCode() + (Error ?? "").GetHashCode();
        }
    }
}
