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
}
