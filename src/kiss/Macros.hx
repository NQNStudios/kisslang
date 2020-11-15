package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import kiss.Reader;
import kiss.Kiss;

using kiss.Helpers;

// Macros generate new Kiss reader expressions from the arguments of their call expression.
typedef MacroFunction = (Array<ReaderExp>, KissState) -> ReaderExp;

class Macros {
    public static function builtins() {
        var macros:Map<String, MacroFunction> = [];

        macros["+"] = foldMacro("Prelude.add");

        macros["-"] = foldMacro("Prelude.subtract");

        macros["*"] = foldMacro("Prelude.multiply");

        macros["/"] = foldMacro("Prelude.divide");

        macros["%"] = (exps:Array<ReaderExp>, k) -> {
            if (exps.length != 2) {
                throw 'Got ${exps.length} arguments for % instead of 2.';
            }
            CallExp(Symbol("Prelude.mod"), [exps[1], exps[0]]);
        };

        macros["^"] = (exps:Array<ReaderExp>, k) -> {
            if (exps.length != 2) {
                throw 'Got ${exps.length} arguments for ^ instead of 2.';
            }
            CallExp(Symbol("Prelude.pow"), [exps[1], exps[0]]);
        };

        macros["min"] = foldMacro("Prelude.minInclusive");

        macros["_min"] = foldMacro("Prelude._minExclusive");

        macros["max"] = foldMacro("Prelude.maxInclusive");

        macros["_max"] = foldMacro("Prelude._maxExclusive");

        macros["_eq"] = foldMacro("Prelude.areEqual");

        // TODO when

        // Under the hood, (defmacro ...) defines a runtime function that accepts Quote arguments and a special form that quotes the arguments to macro calls
        macros["defmacro"] = (exps:Array<ReaderExp>, k:KissState) -> {
            if (exps.length < 3)
                throw '${exps.length} is not enough arguments for (defmacro [name] [args] [body])';
            var macroName = switch (exps[0]) {
                case Symbol(name): name;
                default: throw 'first argument ${exps[0]} for defmacro should be a symbol for the macro name';
            };
            k.specialForms[macroName] = (callArgs:Array<ReaderExp>, convert) -> {
                ECall(Context.parse('${k.className}.${macroName}', Context.currentPos()), [
                    for (callArg in callArgs)
                        EFunction(FArrow, {
                            args: [],
                            ret: null,
                            expr: EReturn(k.convert(callArg)).withPos()
                        }).withPos()
                ]).withPos();
            };

            CallExp(Symbol("defun"), exps);
        }

        return macros;
    }

    static function foldMacro(func:String):MacroFunction {
        return (exps, k) -> {
            CallExp(Symbol("Lambda.fold"), [ListExp(exps.slice(1)), Symbol(func), exps[0]]);
        };
    }
}