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

    public static function minExclusive(a, b) {
        return if (a == b) null else Math.min(a, b);
    }

    public static function maxInclusive(a, b) {
        return Math.max(a, b);
    }

    public static function maxExclusive(a, b) {
        return if (a == b) null else Math.max(a, b);
    }

    public static function areEqual(a, b) {
        return if (a == b) a else null;
    }
}
