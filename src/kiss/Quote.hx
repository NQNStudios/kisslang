package kiss;

/** Under the hood, a quoted expression is just a zero-argument lambda that returns the value. **/
// TODO this type isn't actually used for anything yet, but may come in handy
abstract Quote<T>(Void->T) from Void->T to Void->T {
    public inline function new(unquote:Void->T) {
        this = unquote;
    }

    @:from
    public static function fromLambda<T>(unquote:Void->T) {
        return new Quote(unquote);
    }

    @:to
    public function toLambda<T>() {
        return this;
    }
}
