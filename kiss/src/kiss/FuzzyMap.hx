package kiss;

import haxe.ds.StringMap;
import kiss.FuzzyMapTools;

using hx.strings.Strings;

@:forward(clear, copy, iterator, keyValueIterator, keys, toString)
abstract FuzzyMap<T>(StringMap<T>) from StringMap<T> to StringMap<T> {
    public inline function new(?m:StringMap<T>) {
        this = if (m != null) m else new StringMap<T>();
    }

    @:from
    static public function fromMap<T>(m:StringMap<T>) {
        return new FuzzyMap<T>(m);
    }

    @:to
    public function toMap() {
        return this;
    }

    function bestMatch(fuzzySearchKey:String, ?throwIfNone=true):String {
        return FuzzyMapTools.bestMatch(this, fuzzySearchKey, throwIfNone);
    }

    @:arrayAccess
    public inline function get(fuzzySearchKey:String):Null<T> {
        var match = bestMatch(fuzzySearchKey);
        var value = this.get(match);
        if (match != null) {
            FuzzyMapTools.onMatchMade(this, fuzzySearchKey, value);
        }
        return value;
    }

    public inline function remove(fuzzySearchKey:String):Bool {
        var key = bestMatch(fuzzySearchKey, false);
        if (key == null) return false;
        return this.remove(key);
    }

    public inline function exists(fuzzySearchKey:String):Bool {
        return bestMatch(fuzzySearchKey, false) != null;
    }

    public inline function existsExactly(searchKey:String):Bool {
        return this.exists(searchKey);
    }

    @:arrayAccess
    public inline function set(key:String, v:T):T {
        this.set(key, v);
        return v;
    }
}
