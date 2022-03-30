package prokgen.generators;

import prokgen.ProkMath;
import prokgen.ProkRandom;

class IntGen implements Generator<Int> {
    private var min:Int;
    private var max:Int;
    private var r:ProkRandom;

    public function new(min:Int = ProkMath.MIN_VALUE_INT, max:Int = ProkMath.MAX_VALUE_INT) {
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
            var abs = r.int(0, Std.int(Math.abs(if (sign == minSign) min else max)));
            Std.int(sign * abs);
        } else {
            r.int(min, max);
        };
    }

    public function combine(a:Int, b:Int) {
        var minSign = min / Math.abs(min);
        var maxSign = max / Math.abs(max);

        // Avoid overflow when taking the mean:
        return if (minSign == maxSign) {
            var halfDiff = Math.abs(a - b) / 2;
            Math.round(Math.min(a, b) + halfDiff);
        } else {
            Math.round((a + b) / 2);
        }
    }
}
