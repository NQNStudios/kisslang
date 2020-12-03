package kiss;

using Std;

import kiss.Operand;
import haxe.ds.Either;

class Prelude {
    // Kiss arithmetic will incur overhead because of these switch statements, but the results will not be platform-dependent
    public static function add(a:Operand, b:Operand):Operand {
        return switch ([a, b]) {
            case [Left(str), Left(str2)]:
                Left(str2 + str);
            case [Right(f), Right(f2)]:
                Right(f + f2);
            default:
                throw 'cannot add mismatched types ${Operand.toDynamic(a)} and ${Operand.toDynamic(b)}';
        };
    }

    public static function subtract(val:Operand, from:Operand):Operand {
        return switch ([from, val]) {
            case [Right(from), Right(val)]:
                Right(from - val);
            default:
                throw 'cannot subtract ${Operand.toDynamic(val)} from ${Operand.toDynamic(from)}';
        }
    }

    public static function multiply(a:Operand, b:Operand):Operand {
        return switch ([a, b]) {
            case [Right(f), Right(f2)]:
                Right(f * f2);
            case [Left(a), Left(b)]:
                throw 'cannot multiply strings "$a" and "$b"';
            case [Right(i), Left(s)] | [Left(s), Right(i)] if (i % 1 == 0):
                var result = "";
                for (_ in 0...Math.floor(i)) {
                    result += s;
                }
                Left(result);
            default:
                throw 'cannot multiply ${Operand.toDynamic(a)} and ${Operand.toDynamic(b)}';
        };
    }

    public static function divide(bottom:Operand, top:Operand):Operand {
        return switch ([top, bottom]) {
            case [Right(f), Right(f2)]:
                Right(f / f2);
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

    public static function min(a:Operand, b:Operand):Operand {
        return Right(Math.min(a.toFloat(), b.toFloat()));
    }

    public static function max(a:Operand, b:Operand):Operand {
        return Right(Math.max(a.toFloat(), b.toFloat()));
    }

    public static function greaterThan(b:Operand, a:Operand):Null<Operand> {
        return if (a == null || b == null) null else if (a.toFloat() > b.toFloat()) b else null;
    }

    public static function greaterEqual(b:Operand, a:Operand):Null<Operand> {
        return if (a == null || b == null) null else if (a.toFloat() >= b.toFloat()) b else null;
    }

    public static function lessThan(b:Operand, a:Operand):Null<Operand> {
        return if (a == null || b == null) null else if (a.toFloat() < b.toFloat()) b else null;
    }

    public static function lesserEqual(b:Operand, a:Operand):Null<Operand> {
        return if (a == null || b == null) null else if (a.toFloat() <= b.toFloat()) b else null;
    }

    public static function areEqual(a:Operand, b:Operand):Operand {
        return if (Operand.toDynamic(a) == Operand.toDynamic(b)) a else null;
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
