package prokgen.generators;

import prokgen.ProkMath;
import prokgen.ProkRandom;

class FloatGen implements Generator<Float> {
    private var min:Float;
    private var max:Float;
    private var r:ProkRandom;

    public function new(min:Float = -ProkMath.MAX_VALUE_FLOAT, max:Float = ProkMath.MAX_VALUE_FLOAT) {
        this.min = min;
        this.max = max;
    }

    public function use(r:ProkRandom) {
        this.r = r;
    }

    public function makeRandom() {
        var minSign = min / Math.abs(min);
        var maxSign = max / Math.abs(max);

        return if (minSign != maxSign) {
            var sign = r.getObject([minSign, maxSign], [Math.abs(min)/Math.abs(max), 1]);
            var abs = r.float(0, Math.abs(if (sign == minSign) min else max));
            sign * abs;
        } else {
            r.float(min, max);
        };

    }

    public function combine(a:Float, b:Float) {
        var minSign = min / Math.abs(min);
        var maxSign = max / Math.abs(max);

        // Avoid overflow when taking the mean:
        return if (minSign == maxSign) {
            var halfDiff = Math.abs(a - b) / 2;
            Math.min(a, b) + halfDiff;
        } else {
            (a + b) / 2;
        }
    }
}
