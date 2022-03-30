package prokgen.generators;

enum ArrayCombineBehavior {
    ShortestLength;
    LongestLength;
}

class ArrayGen<T> implements Generator<Array<T>> {
    var elementGen:Generator<T>;
    var minLength:Int;
    var maxLength:Int;
    var r:ProkRandom;
    var behavior:ArrayCombineBehavior;

    public function new(elementGen:Generator<T>, minLength:Int, maxLength:Int, behavior:ArrayCombineBehavior = ShortestLength) {
        this.elementGen = elementGen;
        this.minLength = minLength;
        this.maxLength = maxLength;
        this.behavior = behavior;
    }

    public function use(r:ProkRandom) {
        this.r = r;
        this.elementGen.use(r);
    }

    public function makeRandom() {
        var length = r.int(minLength, maxLength);
        return [for (_ in 0... length) elementGen.makeRandom()];
    }

    public function combine(a:Array<T>, b:Array<T>) {
        var longest = if (a.length > b.length) a else b;
        var sharedLength = Math.floor(Math.min(a.length, b.length));
        var longestLength = switch (behavior) {
            case LongestLength:
                longest.length;
            case ShortestLength:
                sharedLength;
        };

        return [
            for (i in 0...sharedLength)
                elementGen.combine(a[i], b[i])
        ].concat(
            [
                for (i in sharedLength... longestLength)
                    longest[i]
            ]);
    }
}