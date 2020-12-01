package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import hscript.Parser;
import hscript.Interp;
import uuid.Uuid;
import kiss.Reader;
import kiss.Kiss;
import kiss.CompileError;

using uuid.Uuid;
using kiss.Reader;
using kiss.Helpers;

// Macros generate new Kiss reader expressions from the arguments of their call expression.
typedef MacroFunction = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> Null<ReaderExp>;

class Macros {
    public static function builtins() {
        var macros:Map<String, MacroFunction> = [];

        macros["+"] = foldMacro("Prelude.add");

        macros["-"] = foldMacro("Prelude.subtract");

        macros["*"] = foldMacro("Prelude.multiply");

        macros["/"] = foldMacro("Prelude.divide");

        macros["%"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k) -> {
            wholeExp.checkNumArgs(2, 2, '(% [divisor] [dividend])');
            CallExp(Symbol("Prelude.mod").withPosOf(wholeExp), [exps[1], exps[0]]).withPosOf(wholeExp);
        };

        macros["^"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k) -> {
            wholeExp.checkNumArgs(2, 2, '(^ [base] [exponent])');
            CallExp(Symbol("Prelude.pow").withPosOf(wholeExp), [exps[1], exps[0]]).withPosOf(wholeExp);
        };

        macros["min"] = foldMacro("Prelude.minInclusive");

        macros["_min"] = foldMacro("Prelude._minExclusive");

        macros["max"] = foldMacro("Prelude.maxInclusive");

        macros["_max"] = foldMacro("Prelude._maxExclusive");

        macros["_eq"] = foldMacro("Prelude.areEqual");

        macros["when"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k) -> {
            wholeExp.checkNumArgs(2, null, "(when [condition] [body...])");
            CallExp(Symbol("if").withPosOf(wholeExp), [
                args[0],
                CallExp(Symbol("begin").withPosOf(wholeExp), args.slice(1)).withPosOf(wholeExp)
            ]).withPos(args[0].pos);
        };

        macros["cond"] = cond;

        // (or... ) uses (cond... ) under the hood
        macros["or"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k) -> {
            var uniqueVarName = "_" + Uuid.v4().toShort();
            var uniqueVarSymbol = Symbol(uniqueVarName).withPos(args[0].pos);

            CallExp(Symbol("begin").withPosOf(wholeExp), [
                CallExp(Symbol("deflocal").withPosOf(wholeExp), [
                    MetaExp("mut", TypedExp("Dynamic", uniqueVarSymbol).withPosOf(wholeExp)).withPosOf(wholeExp),
                    Symbol("null").withPosOf(wholeExp)
                ]).withPos(args[0].pos),
                CallExp(Symbol("cond").withPosOf(wholeExp), [
                    for (arg in args) {
                        CallExp(CallExp(Symbol("set").withPosOf(wholeExp), [uniqueVarSymbol, arg]).withPosOf(wholeExp), [uniqueVarSymbol]).withPosOf(wholeExp);
                    }
                ]).withPosOf(wholeExp)
            ]).withPosOf(wholeExp);
        };

        // (and... uses (cond... ) and (not ...) under the hood)
        macros["and"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k) -> {
            var uniqueVarName = "_" + Uuid.v4().toShort();
            var uniqueVarSymbol = Symbol(uniqueVarName).withPosOf(wholeExp);

            var condCases = [
                for (arg in args) {
                    CallExp(CallExp(Symbol("not").withPosOf(wholeExp),
                        [
                            CallExp(Symbol("set").withPosOf(wholeExp), [uniqueVarSymbol, arg]).withPosOf(wholeExp)
                        ]).withPosOf(wholeExp), [Symbol("null").withPosOf(wholeExp)]).withPosOf(wholeExp);
                }
            ];
            condCases.push(CallExp(Symbol("true").withPosOf(wholeExp), [uniqueVarSymbol]).withPosOf(wholeExp));

            CallExp(Symbol("begin").withPosOf(wholeExp), [
                CallExp(Symbol("deflocal").withPosOf(wholeExp), [
                    MetaExp("mut", TypedExp("Dynamic", uniqueVarSymbol).withPosOf(wholeExp)).withPosOf(wholeExp),
                    Symbol("null").withPosOf(wholeExp)
                ]).withPosOf(wholeExp),
                CallExp(Symbol("cond").withPosOf(wholeExp), condCases).withPosOf(wholeExp)
            ]).withPosOf(wholeExp);
        };

        function arraySet(wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) {
            return CallExp(Symbol("set").withPosOf(wholeExp), [
                CallExp(Symbol("nth").withPosOf(wholeExp), [exps[0], exps[1]]).withPosOf(wholeExp),
                exps[2]
            ]).withPosOf(wholeExp);
        }
        macros["set-nth"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(3, 3, "(set-nth [list] [index] [value])");
            arraySet(wholeExp, exps, k);
        };
        macros["dict-set"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(3, 3, "(dict-set [dict] [key] [value])");
            arraySet(wholeExp, exps, k);
        };

        // Under the hood, (defmacrofun ...) defines a runtime function that accepts Quote arguments and a special form that quotes the arguments to macrofun calls
        macros["defmacrofun"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(3, null, "(defmacrofun [name] [args] [body...])");
            var macroName = switch (exps[0].def) {
                case Symbol(name): name;
                default: throw CompileError.fromExp(exps[0], 'first argument for defmacrofun should be a symbol for the macro name');
            };
            var macroNumArgs = switch (exps[1].def) {
                case ListExp(argNames): argNames.length;
                default: throw CompileError.fromExp(exps[1], 'second argument of defmacrofun should be a list of argument names');
            };
            k.specialForms[macroName] = (wholeExp:ReaderExp, callArgs:Array<ReaderExp>, convert) -> {
                // Macro functions don't need to check their argument numbers
                // because macro function calls expand to function calls that the Haxe compiler will check
                ECall(Context.parse('${k.className}.${macroName}', wholeExp.macroPos()), [
                    for (callArg in callArgs)
                        EFunction(FArrow, {
                            args: [],
                            ret: null,
                            expr: EReturn(k.convert(callArg)).withMacroPosOf(wholeExp)
                        }).withMacroPosOf(wholeExp)
                ]).withMacroPosOf(wholeExp);
            };

            CallExp(Symbol("defun").withPosOf(wholeExp), exps).withPosOf(wholeExp);
        }

        // For now, reader macros only support a one-expression body implemented in #|raw haxe|#
        macros["defreadermacro"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(3, 3, '(defreadermacro "[startingString]" [[streamArgName]] [RawHaxe])');
            switch (exps[0].def) {
                case StrExp(s):
                    switch (exps[1].def) {
                        case ListExp([{pos: _, def: Symbol(streamArgName)}]):
                            switch (exps[2].def) {
                                case RawHaxe(code):
                                    k.readTable[s] = (stream) -> {
                                        var parser = new Parser();
                                        var interp = new Interp();
                                        interp.variables.set("ReaderExp", ReaderExpDef);
                                        interp.variables.set(streamArgName, stream);
                                        interp.execute(parser.parseString(code));
                                    };
                                default:
                                    throw CompileError.fromExp(exps[2], 'third argument to defreadermacro should be #|raw haxe|#');
                            }
                        default:
                            throw CompileError.fromExp(exps[1], 'second argument to defreadermacro should be [steamArgName]');
                    }
                default:
                    throw CompileError.fromExp(exps[0], 'first argument to defreadermacro should be a String');
            }

            return null;
        };

        macros["defalias"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, 2, "(defalias [whenItsThis] [makeItThis])");
            k.defAlias(switch (exps[0].def) {
                case Symbol(whenItsThis):
                    whenItsThis;
                default:
                    throw CompileError.fromExp(exps[0], 'first argument to defalias should be a symbol for the alias');
            }, switch (exps[1].def) {
                case Symbol(makeItThis):
                    makeItThis;
                default:
                    throw CompileError.fromExp(exps[1], 'second argument to defalias should be a symbol for what the alias becomes');
            });

            return null;
        };

        return macros;
    }

    // cond expands telescopically into a nested if expression
    static function cond(wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) {
        wholeExp.checkNumArgs(1, null, "(cond [cases...])");
        return switch (exps[0].def) {
            case CallExp(condition, body):
                CallExp(Symbol("if").withPosOf(wholeExp), [
                    condition,
                    CallExp(Symbol("begin").withPosOf(wholeExp), body).withPosOf(wholeExp),
                    if (exps.length > 1) {
                        cond(CallExp(Symbol("cond").withPosOf(wholeExp), exps.slice(1)).withPosOf(wholeExp), exps.slice(1), k);
                    } else {
                        Symbol("null").withPosOf(wholeExp);
                    }
                ]).withPosOf(wholeExp);
            default:
                throw CompileError.fromExp(exps[0], 'top-level expression of (cond... ) must be a call list starting with a condition expression');
        };
    }

    static function foldMacro(func:String):MacroFunction {
        return (wholeExp:ReaderExp, exps:Array<ReaderExp>, k) -> {
            // Lambda.fold calls need at least 1 argument
            wholeExp.checkNumArgs(1, null);

            var uniqueVarExps = [];
            var bindingList = [];

            for (exp in exps) {
                var uniqueVarName = "_" + Uuid.v4().toShort();
                var uniqueVarSymbol = Symbol(uniqueVarName).withPosOf(wholeExp);
                uniqueVarExps.push(uniqueVarSymbol);
                bindingList = bindingList.concat([TypedExp("kiss.Operand", uniqueVarSymbol).withPosOf(wholeExp), exp]);
            };

            CallExp(Symbol("let").withPosOf(wholeExp), [
                ListExp(bindingList).withPosOf(wholeExp),
                CallExp(Symbol("Lambda.fold").withPosOf(wholeExp), [
                    ListExp(uniqueVarExps.slice(1)).withPosOf(wholeExp),
                    Symbol(func).withPosOf(wholeExp),
                    uniqueVarExps[0]
                ]).withPosOf(wholeExp)
            ]).withPosOf(wholeExp);
        };
    }
}
