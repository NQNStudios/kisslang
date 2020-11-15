package kiss;

import kiss.Reader;

// Macros generate Kiss new reader from the arguments of their call expression.
typedef MacroFunction = (Array<ReaderExp>) -> ReaderExp;

class Macros {
    public static function builtins() {
        var macros:Map<String, MacroFunction> = [];

        macros["+"] = foldMacro("Prelude.add");

        macros["-"] = foldMacro("Prelude.subtract");

        macros["*"] = foldMacro("Prelude.multiply");

        macros["/"] = foldMacro("Prelude.divide");

        macros["%"] = (exps:Array<ReaderExp>) -> {
            if (exps.length != 2) {
                throw 'Got ${exps.length} arguments for % instead of 2.';
            }
            CallExp(Symbol("Prelude.mod"), [exps[1], exps[0]]);
        };

        macros["^"] = (exps:Array<ReaderExp>) -> {
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

        return macros;
    }

    static function foldMacro(func:String):MacroFunction {
        return (exps) -> {
            CallExp(Symbol("Lambda.fold"), [ListExp(exps.slice(1)), Symbol(func), exps[0]]);
        };
    }
}
