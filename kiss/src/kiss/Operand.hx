package kiss;

import haxe.ds.Either;

/**
    Arithmetic operands
**/
abstract Operand(Either<String, Float>) from Either<String, Float> to Either<String, Float> {
    @:from inline static function fromString(s:String):Operand {
        return Left(s);
    }

    @:from inline static function fromInt(i:Int):Operand {
        return Right(0.0 + i);
    }

    @:from inline static function fromFloat(f:Float):Operand {
        return Right(0.0 + f);
    }

    @:from inline static function fromBool(b:Bool):Operand {
        return if (b == true) Right(Math.POSITIVE_INFINITY) else Right(Math.NEGATIVE_INFINITY);
    }

    // Doing this one implicitly just wasn't working in conjunction with Lambda.fold

    /* @:from */
    public inline static function fromDynamic(d:Dynamic):Operand {
        return switch (Type.typeof(d)) {
            case TInt | TFloat: Right(0.0 + d);
            // Treating true and false as operands can be useful for equality. In practice, no one should use them
            // as operands for any other reason
            case TBool:
                fromBool(d);
            default:
                if (Std.isOfType(d, String)) {
                    Left(d);
                }
                    // Taking a gamble here that no one will ever try to pass a different kind of Either as an operand,
                // because at runtime this is as specific as the check can get.
                else if (Std.isOfType(d, Either)) {
                    d;
                } else {
                    throw '$d cannot be converted to Operand';
                };
        };
    }

    @:to public inline function toString():Null<String> {
        return switch (this) {
            case Left(s): s;
            default: null;
        };
    }

    @:to public inline function toFloat():Null<Float> {
        return switch (this) {
            case Right(f): f;
            default: null;
        };
    }

    @:to public inline function toInt():Null<Int> {
        return switch (this) {
            case Right(f): Math.floor(f);
            default: null;
        };
    }

    @:to public inline function toBool():Null<Bool> {
        return switch (this) {
            case Right(f) if (f == Math.POSITIVE_INFINITY): true;
            case Right(f) if (f == Math.NEGATIVE_INFINITY): false;
            default: null;
        }
    }

    // This wasn't working as an implicit conversion in conjunction with Lambda.fold()

    /* @:to */
    public static function toDynamic(o:Dynamic):Null<Dynamic> {
        return if (Std.isOfType(o, Either)) {
            var o:Operand = cast o;
            switch (o) {
                case Right(f): f;
                case Left(str): str;
            };
        } else {
            o;
        };
    }
}
