package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import kiss.Reader;
import kiss.Types;

// Special forms convert Kiss reader expressions into Haxe macro expressions
typedef SpecialFormFunction = (args:Array<ReaderExp>, convert:ExprConversion) -> Expr;

class SpecialForms {
    public static function builtins() {
        var map:Map<String, SpecialFormFunction> = [];

        map["begin"] = (args:Array<ReaderExp>, convert:ExprConversion) -> {
            pos: Context.currentPos(),
            expr: EBlock([for (bodyExp in args) convert(bodyExp)])
        };

        map["nth"] = (args:Array<ReaderExp>, convert:ExprConversion) -> {
            pos: Context.currentPos(),
            expr: EArray(convert(args[0]), convert(args[1]))
        };

        return map;
    }
}
