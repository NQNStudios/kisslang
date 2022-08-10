package jigsawx.math;
class Vec2{
    public var x: Float;
    public var y: Float;
    public function new( x_ = .0, y_ = .0 ){
        x = x_;
        y = y_;
    }
    public function copy() {
        return new Vec2(x, y);
    }
    public function toString() {
        return '(${x}, ${y})';
    }
}
