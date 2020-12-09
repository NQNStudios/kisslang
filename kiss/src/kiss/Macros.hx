package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import hscript.Parser;
import hscript.Interp;
import uuid.Uuid;
import kiss.Reader;
import kiss.Kiss;
import kiss.CompileError;

using kiss.Kiss;
using uuid.Uuid;
using kiss.Reader;
using kiss.Helpers;

// Macros generate new Kiss reader expressions from the arguments of their call expression.
typedef MacroFunction = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> Null<ReaderExp>;

class Macros {
    public static function builtins() {
        var macros:Map<String, MacroFunction> = [];

        macros["%"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k) -> {
            wholeExp.checkNumArgs(2, 2, '(% [divisor] [dividend])');
            CallExp(Symbol("Prelude.mod").withPosOf(wholeExp), [exps[1], exps[0]]).withPosOf(wholeExp);
        };

        macros["^"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k) -> {
            wholeExp.checkNumArgs(2, 2, '(^ [base] [exponent])');
            CallExp(Symbol("Prelude.pow").withPosOf(wholeExp), [exps[1], exps[0]]).withPosOf(wholeExp);
        };

        macros["+"] = variadicMacro("Prelude.add");

        macros["-"] = variadicMacro("Prelude.subtract");

        macros["*"] = variadicMacro("Prelude.multiply");

        macros["/"] = variadicMacro("Prelude.divide");

        macros["min"] = variadicMacro("Prelude.min");
        macros["max"] = variadicMacro("Prelude.max");

        macros[">"] = variadicMacro("Prelude.greaterThan");
        macros[">="] = variadicMacro("Prelude.greaterEqual");
        macros["<"] = variadicMacro("Prelude.lessThan");
        macros["<="] = variadicMacro("Prelude.lesserEqual");

        macros["="] = variadicMacro("Prelude.areEqual");

        // the (apply [func] [args]) macro keeps its own list of aliases for the math operators
        // that can't just be function aliases because they emulate &rest behavior
        var opAliases = [
            "+" => "Prelude.add", "-" => "Prelude.subtract", "*" => "Prelude.multiply", "/" => "Prelude.divide", ">" => "Prelude.greaterThan",
            ">=" => "Prelude.greaterEqual", "<" => "Prelude.lessThan", "<=" => "Prelude.lesserEqual", "=" => "Prelude.areEqual", "max" => "Prelude.max",
            "min" => "Prelude.min"
        ];

        macros["apply"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k) -> {
            wholeExp.checkNumArgs(2, 2, '(apply [func] [argList])');

            var callOn = switch (exps[0].def) {
                case FieldExp(field, exp):
                    exp;
                default:
                    Symbol("null").withPosOf(wholeExp);
            };
            var func = switch (exps[0].def) {
                case Symbol(sym) if (opAliases.exists(sym)):
                    Symbol(opAliases[sym]).withPosOf(wholeExp);
                default:
                    exps[0];
            };
            var args = switch (exps[0].def) {
                case Symbol(sym) if (opAliases.exists(sym)):
                    ListExp([
                        CallExp(FieldExp("map", exps[1]).withPosOf(wholeExp), [Symbol("kiss.Operand.fromDynamic").withPosOf(wholeExp)]).withPosOf(wholeExp)
                    ]).withPosOf(wholeExp);
                default:
                    exps[1];
            };
            CallExp(Symbol("Reflect.callMethod").withPosOf(wholeExp), [callOn, func, args]).withPosOf(wholeExp);
        };

        macros["range"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k) -> {
            wholeExp.checkNumArgs(1, 3, '(range [?min] [max] [?step])');
            var min = if (exps.length > 1) exps[0] else Symbol("0").withPosOf(wholeExp);
            var max = if (exps.length > 1) exps[1] else exps[0];
            var step = if (exps.length > 2) exps[2] else Symbol("1").withPosOf(wholeExp);
            CallExp(Symbol("Prelude.range").withPosOf(wholeExp), [min, max, step]).withPosOf(wholeExp);
        };

        function bodyIf(formName:String, negated:Bool, wholeExp:ReaderExp, args:Array<ReaderExp>, k) {
            wholeExp.checkNumArgs(2, null, '($formName [condition] [body...])');
            var condition = if (negated) {
                CallExp(Symbol("not").withPosOf(args[0]), [args[0]]).withPosOf(args[0]);
            } else {
                args[0];
            }
            return CallExp(Symbol("if").withPosOf(wholeExp), [
                condition,
                CallExp(Symbol("begin").withPosOf(wholeExp), args.slice(1)).withPosOf(wholeExp)
            ]).withPosOf(wholeExp);
        }
        macros["when"] = bodyIf.bind("when", false);
        macros["unless"] = bodyIf.bind("unless", true);

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

        macros["assert"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(1, 2, "(assert [expression] [message])");
            var expression = exps[0];
            var basicMessage = 'Assertion ${expression.def.toString()} failed';
            var messageExp = if (exps.length > 1) {
                CallExp(Symbol("+").withPosOf(wholeExp), [StrExp(basicMessage + ": ").withPosOf(wholeExp), exps[1]]);
            } else {
                StrExp(basicMessage);
            };
            CallExp(Symbol("unless").withPosOf(wholeExp), [
                expression,
                CallExp(Symbol("throw").withPosOf(wholeExp), [messageExp.withPosOf(wholeExp)]).withPosOf(wholeExp)
            ]).withPosOf(wholeExp);
        };

        macros["defreadermacro"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(3, 3, '(defreadermacro ["[startingString]" or [startingStrings...]] [[streamArgName]] [RawHaxe])');

            // reader macros can define a list of strings that will trigger the macro. When there are multiple,
            // the macro will put back the initiating string into the stream so you can check which one it was
            var stringsThatMatch = switch (exps[0].def) {
                case StrExp(s):
                    [s];
                case ListExp(strings):
                    [
                        for (s in strings)
                            switch (s.def) {
                                case StrExp(s):
                                    s;
                                default:
                                    throw CompileError.fromExp(s, 'initiator list of defreadermacro must only contain strings');
                            }
                    ];
                default:
                    throw CompileError.fromExp(exps[0], 'first argument to defreadermacro should be a String or list of strings');
            };

            for (s in stringsThatMatch) {
                switch (exps[1].def) {
                    case ListExp([{pos: _, def: Symbol(streamArgName)}]):
                        // For now, reader macros only support a one-expression body implemented in #|raw haxe|# (which can contain a block).
                        switch (exps[2].def) {
                            case RawHaxe(code):
                                k.readTable[s] = (stream) -> {
                                    if (stringsThatMatch.length > 1) {
                                        stream.putBackString(s);
                                    }
                                    var parser = new Parser();
                                    var interp = new Interp();
                                    // TODO reader macros also need to access the readtable
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
            }, exps[1].def);
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

    static function variadicMacro(func:String):MacroFunction {
        return (wholeExp:ReaderExp, exps:Array<ReaderExp>, k) -> {
            CallExp(Symbol(func).withPosOf(wholeExp), [
                ListExp([
                    for (exp in exps) {
                        CallExp(Symbol("kiss.Operand.fromDynamic").withPosOf(wholeExp), [exp]).withPosOf(wholeExp);
                    }
                ]).withPosOf(wholeExp)
            ]).withPosOf(wholeExp);
        };
    }
}
