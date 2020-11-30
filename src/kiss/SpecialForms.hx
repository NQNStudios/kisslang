package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import kiss.Reader;
import kiss.Types;
import uuid.Uuid;

using uuid.Uuid;
using kiss.Reader;
using kiss.Helpers;
using kiss.Prelude;

// Special forms convert Kiss reader expressions into Haxe macro expressions
typedef SpecialFormFunction = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> Expr;

class SpecialForms {
    public static function builtins() {
        var map:Map<String, SpecialFormFunction> = [];

        map["begin"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
            // Sometimes empty blocks are useful, so a checkNumArgs() seems unnecessary here for now.

            EBlock([for (bodyExp in args) convert(bodyExp)]).withContextPos();
        };

        map["nth"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
            wholeExp.checkNumArgs(2, 2, "(nth [list] [idx])");
            EArray(convert(args[0]), convert(args[1])).withContextPos();
        };

        function makeQuickNth(idx:Int, name:String) {
            map[name] = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
                wholeExp.checkNumArgs(1, 1, '($name [list])');
                EArray(convert(args[0]), macro $v{idx}).withContextPos();
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

        map["new"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
            wholeExp.checkNumArgs(1, null, '(new [type] [constructorArgs...])');
            var classType = switch (args[0].def) {
                case Symbol(name): name;
                default: throw CompileError.fromExp(args[0], 'first arg in (new [type] ...) should be a class to instantiate');
            };
            ENew(Helpers.parseTypePath(classType, args[0]), args.slice(1).map(convert)).withContextPos();
        };

        map["set"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
            wholeExp.checkNumArgs(2, 2, "(set [variable] [value])");
            EBinop(OpAssign, convert(args[0]), convert(args[1])).withContextPos();
        };

        function toVar(nameExp:ReaderExp, valueExp:ReaderExp, convert:ExprConversion, ?isFinal:Bool):Var {
            // This check seems like unnecessary repetition but it's not. It allows is so that individual destructured bindings can specify mutability
            return if (isFinal == null) {
                switch (nameExp.def) {
                    case MetaExp("mut", innerNameExp):
                        toVar(innerNameExp, valueExp, convert, false);
                    default:
                        toVar(nameExp, valueExp, convert, true);
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
                expr: convert(valueExp)
            };
        }

        function toVars(namesExp:ReaderExp, valueExp:ReaderExp, convert:ExprConversion, ?isFinal:Bool):Array<Var> {
            return if (isFinal == null) {
                switch (namesExp.def) {
                    case MetaExp("mut", innerNamesExp):
                        toVars(innerNamesExp, valueExp, convert, false);
                    default:
                        toVars(namesExp, valueExp, convert, true);
                };
            } else {
                switch (namesExp.def) {
                    case Symbol(_) | TypedExp(_, {pos: _, def: Symbol(_)}):
                        [toVar(namesExp, valueExp, convert, isFinal)];
                    case ListExp(nameExps):
                        var idx = 0;
                        [
                            for (nameExp in nameExps)
                                toVar(nameExp,
                                    CallExp(Symbol("nth").withPosOf(valueExp), [valueExp, Symbol(Std.string(idx++)).withPosOf(valueExp)]).withPosOf(valueExp),
                                    convert, if (isFinal == false) false else null)
                        ];
                    default:
                        throw CompileError.fromExp(namesExp, "Can only bind variables to a symbol or list of symbols for destructuring");
                };
            };
        }

        map["deflocal"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
            wholeExp.checkNumArgs(2, 3, "(deflocal [optional :type] [variable] [optional: &mut] [value])");
            EVars(toVars(args[0], args[1], convert)).withContextPos();
        };

        map["let"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
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
                varDefs = varDefs.concat(toVars(bindingPair[0], bindingPair[1], convert));
            }

            var body = args.slice(1);
            if (body.length == 0) {
                throw CompileError.fromArgs(args, '(let....) expression needs a body');
            }

            EBlock([EVars(varDefs).withContextPos(), EBlock(body.map(convert)).withContextPos()]).withContextPos();
        };

        map["lambda"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
            wholeExp.checkNumArgs(2, null, "(lambda [[argsNames...]] [body...])");
            EFunction(FArrow, Helpers.makeFunction(null, args[0], args.slice(1), convert)).withContextPos();
        };

        function forExpr(formName:String, wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) {
            wholeExp.checkNumArgs(3, null, '($formName [varName] [list] [body...])');
            var uniqueVarName = "_" + Uuid.v4().toShort();
            var namesExp = args[0];
            var listExp = args[1];
            var bodyExps = args.slice(2);
            bodyExps.insert(0, CallExp(Symbol("deflocal").withPosOf(args[2]), [namesExp, Symbol(uniqueVarName).withPosOf(args[2])]).withPosOf(args[2]));
            var body = CallExp(Symbol("begin").withPosOf(args[2]), bodyExps).withPosOf(args[2]);
            return EFor(EBinop(OpIn, EConst(CIdent(uniqueVarName)).withContextPos(), convert(listExp)).withContextPos(), convert(body)).withContextPos();
        }

        map["doFor"] = forExpr.bind("doFor");
        map["for"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
            EArrayDecl([forExpr("for", wholeExp, args, convert)]).withContextPos();
        };

        // TODO (case... ) for switch

        // Type check syntax:
        map["the"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
            wholeExp.checkNumArgs(2, 2, '(the [type] [value])');
            ECheckType(convert(args[1]), switch (args[0].def) {
                case Symbol(type): Helpers.parseComplexType(type, args[0]);
                default: throw CompileError.fromExp(args[0], 'first argument to (the... ) should be a valid type');
            }).withContextPos();
        };

        map["try"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
            wholeExp.checkNumArgs(1, null, "(try [thing] [catches...])");
            var tryKissExp = args[0];
            var catchKissExps = args.slice(1);
            ETry(convert(tryKissExp), [
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
                                expr: convert(CallExp(Symbol("begin").withPos(catchArgs[1].pos), catchArgs.slice(1)).withPos(catchArgs[1].pos))
                            };
                        default:
                            throw CompileError.fromExp(catchKissExp,
                                'expressions following the first expression in a (try... ) should all be (catch [[error]] [body...]) expressions');
                    }
                }
            ]).withContextPos();
        };

        map["throw"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
            if (args.length != 1) {
                throw CompileError.fromExp(wholeExp, 'throw expression should only throw one value');
            }
            EThrow(convert(args[0])).withContextPos();
        };

        map["<"] = foldComparison("_min");
        map["<="] = foldComparison("min");
        map[">"] = foldComparison("_max");
        map[">="] = foldComparison("max");
        map["="] = foldComparison("_eq");

        map["if"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
            wholeExp.checkNumArgs(2, 3, '(if [cond] [then] [?else])');

            var condition = macro Prelude.truthy(${convert(args[0])});
            var thenExp = convert(args[1]);
            var elseExp = if (args.length > 2) {
                convert(args[2]);
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

        map["not"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
            if (args.length != 1)
                throw CompileError.fromExp(wholeExp, '(not... ) only takes one argument, not $args');
            var condition = convert(args[0]);
            var truthyExp = macro Prelude.truthy($condition);
            macro !$truthyExp;
        };

        return map;
    }

    static function foldComparison(func:String) {
        return (wholeExp:ReaderExp, args:Array<ReaderExp>, convert:ExprConversion) -> {
            wholeExp.checkNumArgs(1, null);
            EBinop(OpEq, convert(args[0]), convert(CallExp(Symbol(func).withPosOf(wholeExp), args).withPosOf(wholeExp))).withContextPos();
        };
    }
}
