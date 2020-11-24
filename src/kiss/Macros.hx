package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import hscript.Parser;
import hscript.Interp;
import kiss.Reader;
import kiss.Kiss;

using kiss.Helpers;

// Macros generate new Kiss reader expressions from the arguments of their call expression.
typedef MacroFunction = (Array<ReaderExp>, KissState) -> Null<ReaderExp>;

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

        // Under the hood, (defmacrofun ...) defines a runtime function that accepts Quote arguments and a special form that quotes the arguments to macrofun calls
        macros["defmacrofun"] = (exps:Array<ReaderExp>, k:KissState) -> {
            if (exps.length < 3)
                throw '${exps.length} is not enough arguments for (defmacrofun [name] [args] [body])';
            var macroName = switch (exps[0]) {
                case Symbol(name): name;
                default: throw 'first argument ${exps[0]} for defmacrofun should be a symbol for the macro name';
            };
            k.specialForms[macroName] = (callArgs:Array<ReaderExp>, convert) -> {
                ECall(Context.parse('${k.className}.${macroName}', Context.currentPos()), [
                    for (callArg in callArgs)
                        EFunction(FArrow, {
                            args: [],
                            ret: null,
                            expr: EReturn(k.convert(callArg)).withContextPos()
                        }).withContextPos()
                ]).withContextPos();
            };

            CallExp(Symbol("defun"), exps);
        }

        // For now, reader macros only support a one-expression body implemented in #|raw haxe|#
        macros["defreadermacro"] = (exps:Array<ReaderExp>, k:KissState) -> {
            if (exps.length != 3) {
                throw 'wrong number of expressions for defreadermacro: $exps should be String, [streamArgName], RawHaxe';
            }
            switch (exps[0]) {
                case StrExp(s):
                    switch (exps[1]) {
                        case ListExp([Symbol(streamArgName)]):
                            switch (exps[2]) {
                                case RawHaxe(code):
                                    k.readTable[s] = (stream) -> {
                                        var parser = new Parser();
                                        var interp = new Interp();
                                        interp.variables.set("ReaderExp", ReaderExp);
                                        interp.variables.set(streamArgName, stream);
                                        interp.execute(parser.parseString(code));
                                    };
                                default:
                                    throw 'third argument to defreadermacro should be #|raw haxe|#, not ${exps[2]}';
                            }
                        default:
                            throw 'second argument to defreadermacro should be [steamArgName], not ${exps[1]}';
                    }
                default:
                    throw 'first argument to defreadermacro should be a String, not ${exps[0]}';
            }

            return null;
        };

        return macros;
    }

    static function foldMacro(func:String):MacroFunction {
        return (exps, k) -> {
            CallExp(Symbol("Lambda.fold"), [ListExp(exps.slice(1)), Symbol(func), exps[0]]);
        };
    }
}
