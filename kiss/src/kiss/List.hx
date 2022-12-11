package kiss;

/**
    Kiss enhances Haxe Arrays to support negative indices and return nullable-typed values.
**/
@:forward(length, concat, contains, copy, filter, indexOf, // insert is re-implemented with negative index support
    iterator, join, keyValueIterator,
    lastIndexOf, map, pop, push, remove, resize, reverse, shift, // slice is re-implemented with negative index support
    sort,
    // splice is re-implemented with negative index support,
    toString, unshift)
abstract List<T>(Array<T>) from Array<T> to Array<T> {
    public inline function new(a:Array<T>) {
        this = a;
    }

    @:from
    static public function fromArray<T>(a:Array<T>) {
        return new List<T>(a);
    }

    @:to
    public function toArray() {
        return this;
    }

    inline function realIndex(idx:Int) {
        return if (idx < 0) this.length + idx else idx;
    }

    @:arrayAccess
    public inline function get(idx:Int):Null<T> {
        return this[realIndex(idx)];
    }

    @:arrayAccess
    public inline function arrayWrite(idx:Int, v:T):T {
        this[realIndex(idx)] = v;
        return v;
    }

    // TODO deleting these should be fine, because the haxe Array functions already allow negative arguments
    public function insert(idx:Int, v:T) {
        this.insert(realIndex(idx), v);
    }

    public function slice(start:Int, ?end:Int) {
        if (end == null)
            end = this.length;
        return this.slice(realIndex(start), realIndex(end));
    }

    public function splice(start:Int, len:Int) {
        return this.splice(realIndex(start), len);
    }
}
