package kiss;

import haxe.ds.StringMap;

using hx.strings.Strings;

abstract FuzzyMap<T>(StringMap<T>) from StringMap<T> to StringMap<T> {
    public inline function new(m:StringMap<T>) {
        this = m;
    }

    @:from
    static public function fromMap<T>(m:StringMap<T>) {
        return new FuzzyMap<T>(m);
    }

    @:to
    public function toMap() {
        return this;
    }

    @:arrayAccess
    public inline function get(searchKey:String):Null<T> {
        var bestMatch:Null<T> = null;
        var bestScore = 0;

        for (key => value in this) {
            var score = searchKey.getFuzzyDistance(key);
            if (score > bestScore) {
                bestScore = score;
                bestMatch = value;
            }
        }

        return bestMatch;
    }

    @:arrayAccess
    public inline function set(key:String, v:T):T {
        this.set(key, v);
        return v;
    }
}
