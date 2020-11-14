package kiss;

import kiss.Reader;

// Macros generate Kiss new reader from the arguments of their call expression.
typedef MacroFunction = (Array<ReaderExp>) -> ReaderExp;

class Macros {
	public static function builtins() {
		var macros:Map<String, MacroFunction> = [];

		macros["+"] = (exps) -> {
			CallExp(Symbol("Lambda.fold"), [ListExp(exps), Symbol("Prelude.add"), Symbol("0")]);
		};

		macros["-"] = (exps:Array<ReaderExp>) -> {
			CallExp(Symbol("Lambda.fold"), [ListExp(exps.slice(1)), Symbol("Prelude.subtract"), exps[0]]);
		}

		return macros;
	}
}
