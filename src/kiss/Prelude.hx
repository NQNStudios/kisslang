package kiss;

class Prelude {
    public static function add(a, b) {
        return a + b;
    }

    public static function subtract(val, from) {
        return from - val;
    }

    public static function multiply(a, b) {
        return a * b;
    }

    public static function divide(bottom:Float, top:Float) {
        return top / bottom;
    }

    public static function mod(bottom, top) {
        return top % bottom;
    }

    public static function pow(exponent, base) {
        return Math.pow(base, exponent);
    }

    public static function minInclusive(a, b) {
        return Math.min(a, b);
    }

    public static function _minExclusive(a, b) {
        return if (a == b) Math.NEGATIVE_INFINITY else Math.min(a, b);
    }

    public static function maxInclusive(a, b) {
        return Math.max(a, b);
    }

    public static function _maxExclusive(a, b) {
        return if (a == b) Math.POSITIVE_INFINITY else Math.max(a, b);
    }

    public static function areEqual(a, b) {
        return if (a == b) a else Math.NaN;
    }

    public static function groups<T>(a:Array<T>, size, keepRemainder = false) {
        var numFullGroups = Math.floor(a.length / size);
        var fullGroups = [
            for (num in 0...numFullGroups) {
                var start = num * size;
                var end = (num + 1) * size;
                a.slice(start, end);
            }
        ];
        if (a.length % size != 0 && keepRemainder) {
            fullGroups.push(a.slice(numFullGroups * size));
        }
        return fullGroups;
    }

    // TODO put truthy in KissState
    // TODO make [] falsy
    public static dynamic function truthy(v:Any) {
        return switch (Type.typeof(v)) {
            case TNull: false;
            case TInt | TFloat: (v : Float) > 0;
            case TBool: (v : Bool);
            default:
                // Empty strings are falsy
                var str = cast(v, String);
                if (str != null) {
                    str.length > 0;
                } else {
                    // Any other value is true by default
                    true;
                }
        }
    }
}
