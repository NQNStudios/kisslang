package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import kiss.Reader;
import uuid.Uuid;

using uuid.Uuid;
using kiss.Reader;
using kiss.Helpers;
using kiss.Prelude;

import kiss.Kiss;

// Special forms convert Kiss reader expressions into Haxe macro expressions
typedef SpecialFormFunction = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> Expr;

class SpecialForms {
    public static function builtins() {
        var map:Map<String, SpecialFormFunction> = [];

        map["begin"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            // Sometimes empty blocks are useful, so a checkNumArgs() seems unnecessary here for now.

            EBlock([for (bodyExp in args) k.convert(bodyExp)]).withContextPos();
        };

        map["nth"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, 2, "(nth [list] [idx])");
            EArray(k.convert(args[0]), k.convert(args[1])).withContextPos();
        };

        function makeQuickNth(idx:Int, name:String) {
            map[name] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
                wholeExp.checkNumArgs(1, 1, '($name [list])');
                EArray(k.convert(args[0]), macro $v{idx}).withContextPos();
            };
        }
        makeQuickNth(0, "first");
        makeQuickNth(1, "second");
        makeQuickNth(2, "third");
        makeQuickNth(3, "fourth");
        makeQuickNth(4, "fifth");
        makeQuickNth(5, "sixth");
        makeQuickNth(6, "seventh");
        makeQuickNth(7, "eighth");
        makeQuickNth(8, "ninth");
        makeQuickNth(9, "tenth");
        makeQuickNth(-1, "last");

        // TODO rest

        // TODO special form for object declaration

        map["new"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(1, null, '(new [type] [constructorArgs...])');
            var classType = switch (args[0].def) {
                case Symbol(name): name;
                default: throw CompileError.fromExp(args[0], 'first arg in (new [type] ...) should be a class to instantiate');
            };
            ENew(Helpers.parseTypePath(classType, args[0]), args.slice(1).map(k.convert)).withContextPos();
        };

        map["set"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, 2, "(set [variable] [value])");
            EBinop(OpAssign, k.convert(args[0]), k.convert(args[1])).withContextPos();
        };

        function toVar(nameExp:ReaderExp, valueExp:ReaderExp, k:KissState, ?isFinal:Bool):Var {
            // This check seems like unnecessary repetition but it's not. It allows is so that individual destructured bindings can specify mutability
            return if (isFinal == null) {
                switch (nameExp.def) {
                    case MetaExp("mut", innerNameExp):
                        toVar(innerNameExp, valueExp, k, false);
                    default:
                        toVar(nameExp, valueExp, k, true);
                };
            } else {
                name: switch (nameExp.def) {
                    case Symbol(name) | TypedExp(_, {pos: _, def: Symbol(name)}):
                        name;
                    default:
                        throw CompileError.fromExp(nameExp, 'expected a symbol or typed symbol for variable name in a var binding');
                },
                type: switch (nameExp.def) {
                    case TypedExp(type, _):
                        Helpers.parseComplexType(type, nameExp);
                    default: null;
                },
                isFinal: isFinal,
                expr: k.convert(valueExp)
            };
        }

        function toVars(namesExp:ReaderExp, valueExp:ReaderExp, k:KissState, ?isFinal:Bool):Array<Var> {
            return if (isFinal == null) {
                switch (namesExp.def) {
                    case MetaExp("mut", innerNamesExp):
                        toVars(innerNamesExp, valueExp, k, false);
                    default:
                        toVars(namesExp, valueExp, k, true);
                };
            } else {
                switch (namesExp.def) {
                    case Symbol(_) | TypedExp(_, {pos: _, def: Symbol(_)}):
                        [toVar(namesExp, valueExp, k, isFinal)];
                    case ListExp(nameExps):
                        var idx = 0;
                        [
                            for (nameExp in nameExps)
                                toVar(nameExp,
                                    CallExp(Symbol("nth").withPosOf(valueExp), [valueExp, Symbol(Std.string(idx++)).withPosOf(valueExp)]).withPosOf(valueExp),
                                    k, if (isFinal == false) false else null)
                        ];
                    default:
                        throw CompileError.fromExp(namesExp, "Can only bind variables to a symbol or list of symbols for destructuring");
                };
            };
        }

        map["deflocal"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, 3, "(deflocal [optional :type] [variable] [optional: &mut] [value])");
            EVars(toVars(args[0], args[1], k)).withContextPos();
        };

        map["let"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, null, "(let [[bindings...]] [body...])");
            var bindingList = switch (args[0].def) {
                case ListExp(bindingExps) if (bindingExps.length > 0 && bindingExps.length % 2 == 0):
                    bindingExps;
                default:
                    throw CompileError.fromExp(args[0], 'let bindings should be a list expression with an even number of sub expressions');
            };
            var bindingPairs = bindingList.groups(2);
            var varDefs = [];
            for (bindingPair in bindingPairs) {
                varDefs = varDefs.concat(toVars(bindingPair[0], bindingPair[1], k));
            }

            var body = args.slice(1);
            if (body.length == 0) {
                throw CompileError.fromArgs(args, '(let....) expression needs a body');
            }

            EBlock([EVars(varDefs).withContextPos(), EBlock(body.map(k.convert)).withContextPos()]).withContextPos();
        };

        map["lambda"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, null, "(lambda [[argsNames...]] [body...])");
            EFunction(FArrow, Helpers.makeFunction(null, args[0], args.slice(1), k)).withContextPos();
        };

        function forExpr(formName:String, wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) {
            wholeExp.checkNumArgs(3, null, '($formName [varName] [list] [body...])');
            var uniqueVarName = "_" + Uuid.v4().toShort();
            var namesExp = args[0];
            var listExp = args[1];
            var bodyExps = args.slice(2);
            bodyExps.insert(0, CallExp(Symbol("deflocal").withPosOf(args[2]), [namesExp, Symbol(uniqueVarName).withPosOf(args[2])]).withPosOf(args[2]));
            var body = CallExp(Symbol("begin").withPosOf(args[2]), bodyExps).withPosOf(args[2]);
            return EFor(EBinop(OpIn, EConst(CIdent(uniqueVarName)).withContextPos(), k.convert(listExp)).withContextPos(), k.convert(body)).withContextPos();
        }

        map["doFor"] = forExpr.bind("doFor");
        map["for"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            EArrayDecl([forExpr("for", wholeExp, args, k)]).withContextPos();
        };

        // TODO (case... ) for switch

        // Type check syntax:
        map["the"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, 2, '(the [type] [value])');
            ECheckType(k.convert(args[1]), switch (args[0].def) {
                case Symbol(type): Helpers.parseComplexType(type, args[0]);
                default: throw CompileError.fromExp(args[0], 'first argument to (the... ) should be a valid type');
            }).withContextPos();
        };

        map["try"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(1, null, "(try [thing] [catches...])");
            var tryKissExp = args[0];
            var catchKissExps = args.slice(1);
            ETry(k.convert(tryKissExp), [
                for (catchKissExp in catchKissExps) {
                    switch (catchKissExp.def) {
                        case CallExp({pos: _, def: Symbol("catch")}, catchArgs):
                            {
                                name: switch (catchArgs[0].def) {
                                    case ListExp([
                                        {
                                            pos: _,
                                            def: Symbol(name) | TypedExp(_, {pos: _, def: Symbol(name)})
                                        }
                                    ]): name;
                                    default: throw CompileError.fromExp(catchArgs[0], 'first argument to (catch... ) should be a one-element argument list');
                                },
                                type: switch (catchArgs[0].def) {
                                    case ListExp([{pos: _, def: TypedExp(type, _)}]):
                                        Helpers.parseComplexType(type, catchArgs[0]);
                                    default: null;
                                },
                                expr: k.convert(CallExp(Symbol("begin").withPos(catchArgs[1].pos), catchArgs.slice(1)).withPos(catchArgs[1].pos))
                            };
                        default:
                            throw CompileError.fromExp(catchKissExp,
                                'expressions following the first expression in a (try... ) should all be (catch [[error]] [body...]) expressions');
                    }
                }
            ]).withContextPos();
        };

        map["throw"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            if (args.length != 1) {
                throw CompileError.fromExp(wholeExp, 'throw expression should only throw one value');
            }
            EThrow(k.convert(args[0])).withContextPos();
        };

        map["<"] = foldComparison("_min");
        map["<="] = foldComparison("min");
        map[">"] = foldComparison("_max");
        map[">="] = foldComparison("max");
        map["="] = foldComparison("_eq");

        map["if"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, 3, '(if [cond] [then] [?else])');

            var condition = macro Prelude.truthy(${k.convert(args[0])});
            var thenExp = k.convert(args[1]);
            var elseExp = if (args.length > 2) {
                k.convert(args[2]);
            } else {
                // Kiss (if... ) expressions all need to generate a Haxe else block
                // to make sure they always return something
                macro null;
            };

            macro if ($condition)
                $thenExp
            else
                $elseExp;
        };

        map["not"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            if (args.length != 1)
                throw CompileError.fromExp(wholeExp, '(not... ) only takes one argument, not $args');
            var condition = k.convert(args[0]);
            var truthyExp = macro Prelude.truthy($condition);
            macro !$truthyExp;
        };

        return map;
    }

    static function foldComparison(func:String) {
        return (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var callFoldMacroExpr = k.convert(CallExp(Symbol(func).withPosOf(wholeExp), args).withPosOf(wholeExp));
            wholeExp.checkNumArgs(1, null);
            EBinop(OpEq, k.convert(args[0]), macro ${callFoldMacroExpr}.toDynamic()).withContextPos();
        };
    }
}
