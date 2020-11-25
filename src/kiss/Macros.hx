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
                throw CompileError.fromArgs(exps, 'Got ${exps.length} arguments for % instead of 2.');
            }
            CallExp(Symbol("Prelude.mod").withPos(exps[0].pos), [exps[1], exps[0]]).withPos(exps[0].pos);
        };

        macros["^"] = (exps:Array<ReaderExp>, k) -> {
            if (exps.length != 2) {
                throw CompileError.fromArgs(exps, 'Got ${exps.length} arguments for ^ instead of 2.');
            }
            CallExp(Symbol("Prelude.pow").withPos(exps[0].pos), [exps[1], exps[0]]).withPos(exps[0].pos);
        };

        macros["min"] = foldMacro("Prelude.minInclusive");

        macros["_min"] = foldMacro("Prelude._minExclusive");

        macros["max"] = foldMacro("Prelude.maxInclusive");

        macros["_max"] = foldMacro("Prelude._maxExclusive");

        macros["_eq"] = foldMacro("Prelude.areEqual");

        // TODO when

        macros["cond"] = cond;

        // (or... ) uses (cond... ) under the hood
        macros["or"] = (args:Array<ReaderExp>, k) -> {
            var uniqueVarName = "_" + Uuid.v4().toShort();
            var uniqueVarSymbol = Symbol(uniqueVarName).withPos(args[0].pos);

            CallExp(Symbol("begin").withPos(args[0].pos), [
                CallExp(Symbol("deflocal").withPos(args[0].pos), [
                    TypedExp("Any", uniqueVarSymbol).withPos(args[0].pos),
                    MetaExp("mut").withPos(args[0].pos),
                    Symbol("null").withPos(args[0].pos)
                ]).withPos(args[0].pos),
                CallExp(Symbol("cond").withPos(args[0].pos), [
                    for (arg in args) {
                        CallExp(CallExp(Symbol("set").withPos(args[0].pos), [uniqueVarSymbol, arg]).withPos(args[0].pos),
                            [uniqueVarSymbol]).withPos(args[0].pos);
                    }
                ]).withPos(args[0].pos)
            ]).withPos(args[0].pos);
        };

        // (and... uses (cond... ) and (not ...) under the hood)
        macros["and"] = (args:Array<ReaderExp>, k) -> {
            var uniqueVarName = "_" + Uuid.v4().toShort();
            var uniqueVarSymbol = Symbol(uniqueVarName).withPos(args[0].pos);

            var condCases = [
                for (arg in args) {
                    CallExp(CallExp(Symbol("not").withPos(args[0].pos),
                        [
                            CallExp(Symbol("set").withPos(args[0].pos), [uniqueVarSymbol, arg]).withPos(args[0].pos)
                        ]).withPos(args[0].pos), [Symbol("null").withPos(args[0].pos)]).withPos(args[0].pos);
                }
            ];
            condCases.push(CallExp(Symbol("true").withPos(args[0].pos), [uniqueVarSymbol]).withPos(args[0].pos));

            CallExp(Symbol("begin").withPos(args[0].pos), [
                CallExp(Symbol("deflocal").withPos(args[0].pos), [
                    TypedExp("Any", uniqueVarSymbol).withPos(args[0].pos),
                    MetaExp("mut").withPos(args[0].pos),
                    Symbol("null").withPos(args[0].pos)
                ]).withPos(args[0].pos),
                CallExp(Symbol("cond").withPos(args[0].pos), condCases).withPos(args[0].pos)
            ]).withPos(args[0].pos);
        };

        // Under the hood, (defmacrofun ...) defines a runtime function that accepts Quote arguments and a special form that quotes the arguments to macrofun calls
        macros["defmacrofun"] = (exps:Array<ReaderExp>, k:KissState) -> {
            if (exps.length < 3)
                throw CompileError.fromArgs(exps, '${exps.length} is not enough arguments for (defmacrofun [name] [args] [body...])');
            var macroName = switch (exps[0].def) {
                case Symbol(name): name;
                default: throw CompileError.fromExp(exps[0], 'first argument for defmacrofun should be a symbol for the macro name');
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

            CallExp(Symbol("defun").withPos(exps[0].pos), exps).withPos(exps[0].pos);
        }

        // For now, reader macros only support a one-expression body implemented in #|raw haxe|#
        macros["defreadermacro"] = (exps:Array<ReaderExp>, k:KissState) -> {
            if (exps.length != 3) {
                throw CompileError.fromArgs(exps, 'wrong number of expressions for defreadermacro. Should be String, [streamArgName], RawHaxe');
            }
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

        return macros;
    }

    // cond expands telescopically into a nested if expression
    static function cond(exps:Array<ReaderExp>, k:KissState) {
        return switch (exps[0].def) {
            case CallExp(condition, body):
                CallExp(Symbol("if").withPos(exps[0].pos), [
                    condition,
                    CallExp(Symbol("begin").withPos(exps[0].pos), body).withPos(exps[0].pos),
                    if (exps.length > 1) {
                        cond(exps.slice(1), k);
                    } else {
                        Symbol("null").withPos(exps[0].pos);
                    }
                ]).withPos(exps[0].pos);
            default:
                throw CompileError.fromExp(exps[0], 'top-level expression of (cond... ) must be a call list starting with a condition expression');
        };
    }

    static function foldMacro(func:String):MacroFunction {
        return (exps:Array<ReaderExp>, k) -> {
            CallExp(Symbol("Lambda.fold").withPos(exps[0].pos), [
                ListExp(exps.slice(1)).withPos(exps[0].pos),
                Symbol(func).withPos(exps[0].pos),
                exps[0]
            ]).withPos(exps[0].pos);
        };
    }
}
