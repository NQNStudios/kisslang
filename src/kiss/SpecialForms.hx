package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import kiss.Reader;
import kiss.Types;

using kiss.Helpers;

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

        // TODO first through tenth

        // TODO special form for object declaration

        // TODO special form for new

        // TODO special form for assignment

        // TODO special form for lambda

        // TODO special form for for loop

        // TODO special form for list comprehension

        // TODO special form for while loop

        // TODO special form for do-while loop

        // TODO special form for switch

        // TODO special form for try

        // TODO special form for throw

        map["<"] = foldComparison("_min");
        map["<="] = foldComparison("min");
        map[">"] = foldComparison("_max");
        map[">="] = foldComparison("max");
        map["="] = foldComparison("_eq");

        map["if"] = (args:Array<ReaderExp>, convert:ExprConversion) -> {
            if (args.length < 2 || args.length > 3) {
                throw 'if statement has wrong number of arguments: ${args.length}';
            }

            var condition = macro Prelude.truthy(${convert(args[0])});
            var thenExp = convert(args[1]);
            var elseExp = if (args.length > 2) convert(args[2]) else null;

            EIf(condition, thenExp, elseExp).withPos();
        };

        return map;
    }

    static function foldComparison(func:String) {
        return (args:Array<ReaderExp>, convert:ExprConversion) -> {
            pos: Context.currentPos(),
            expr: EBinop(OpEq, convert(args[0]), convert(CallExp(Symbol(func), args)))
        };
    }
}
