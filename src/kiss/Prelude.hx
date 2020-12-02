package kiss;

using Std;

import kiss.Operand;
import haxe.ds.Either;

class Prelude {
    // Kiss arithmetic will incur overhead because of these switch statements, but the results will not be platform-dependent
    public static function add(a:Operand, b:Operand):Operand {
        return switch (a) {
            case Left(str):
                var firstStr = if (b.toString() != null) {
                    b.toString();
                } else {
                    throw 'cannot add string $str and float ${b.toFloat()}';
                };
                Left(firstStr + str);
            case Right(Left(i)):
                switch (b) {
                    case Right(Right(f)):
                        add(b, a);
                    case Right(Left(bI)):
                        Right(Left(i + bI));
                    case Left(s): throw 'cannot add int $i and string $s';
                }
            case Right(Right(f)):
                Right(Right(f + if (b.toFloat() != null) b.toFloat() else throw 'cannot add float $f and string ${b.toString()}'));
        };
    }

    public static function subtract(val:Operand, from:Operand):Operand {
        return switch ([from, val]) {
            case [Right(Left(from)), Right(Left(val))]:
                Right(Left(from - val));
            case [Right(_), Right(_)]:
                Right(Right(from.toFloat() - val.toFloat()));
            default:
                throw 'cannot subtract $val from $from';
        }
    }

    public static function multiply(a:Operand, b:Operand):Operand {
        return switch ([a, b]) {
            case [Right(Right(f)), Right(Left(_)) | Right(Right(_))]:
                Right(Right(f * b.toFloat()));
            case [Right(Left(i)), Right(Right(_))]:
                multiply(b, a);
            case [Right(Left(i)), Right(Left(bI))]:
                Right(Left(i * bI));
            case [Left(a), Left(b)]:
                throw 'cannot multiply strings "$a" and "$b"';
            case [Right(Left(i)), Left(s)] | [Left(s), Right(Left(i))]:
                var result = "";
                for (_ in 0...i) {
                    result += s;
                }
                Left(result);
            default:
                throw 'cannot multiply $a and $b';
        };
    }

    public static function divide(bottom:Operand, top:Operand):Operand {
        return switch ([top, bottom]) {
            case [Right(Left(top)), Right(Left(bottom))]:
                Math.floor(top / bottom);
            case [Right(_), Right(_)]:
                top.toFloat() / bottom.toFloat();
            default:
                throw 'cannot divide $top by $bottom';
        };
    }

    public static function mod(bottom:Operand, top:Operand):Float {
        return top.toFloat() % bottom.toFloat();
    }

    public static function pow(exponent:Operand, base:Operand):Float {
        return Math.pow(base.toFloat(), exponent.toFloat());
    }

    public static function minInclusive(a:Operand, b:Operand):Operand {
        return Math.min(a.toFloat(), b.toFloat());
    }

    public static function _minExclusive(a:Operand, b:Operand):Operand {
        return if (a.toFloat() == b.toFloat()) Math.NEGATIVE_INFINITY else Math.min(a.toFloat(), b.toFloat());
    }

    public static function maxInclusive(a:Operand, b:Operand):Operand {
        return Math.max(a.toFloat(), b.toFloat());
    }

    public static function _maxExclusive(a:Operand, b:Operand):Operand {
        return if (a.toFloat() == b.toFloat()) Math.POSITIVE_INFINITY else Math.max(a.toFloat(), b.toFloat());
    }

    public static function areEqual(a:Operand, b:Operand):Operand {
        return if (Operand.toDynamic(a) == Operand.toDynamic(b)) a else Right(Right(Math.NaN));
    }

    public static function groups<T>(a:Array<T>, size, keepRemainder = false) {
        var numFullGroups = Math.floor(a.length / size);
        var fullGroups = [
            for (num in 0...numFullGroups) {
                var start = num * size;
                var end = (num + 1) * size;
                a.slice(start, end);
            }
        ];
        if (a.length % size != 0 && keepRemainder) {
            fullGroups.push(a.slice(numFullGroups * size));
        }
        return fullGroups;
    }

    public static dynamic function truthy(v:Any) {
        return switch (Type.typeof(v)) {
            case TNull: false;
            case TInt | TFloat: (v : Float) > 0;
            case TBool: (v : Bool);
            default:
                // Empty strings are falsy
                if (v.isOfType(String)) {
                    var str:String = cast v;
                    str.length > 0;
                } else if (v.isOfType(Array)) {
                    // Empty lists are falsy
                    var lst:Array<Dynamic> = cast v;
                    lst.length > 0;
                } else {
                    // Any other value is true by default
                    true;
                };
        }
    }

    public static function print<T>(v:T) {
        #if (sys || hxnodejs)
        Sys.println(v);
        #else
        trace(v);
        #end
        return v;
    }
}
