package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import kiss.Reader;
import kiss.ReaderExp;
import uuid.Uuid;
import kiss.Kiss;

using uuid.Uuid;
using kiss.Reader;
using kiss.Helpers;
using kiss.Prelude;
using kiss.Kiss;

// Special forms convert Kiss reader expressions into Haxe macro expressions
typedef SpecialFormFunction = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> Expr;

class SpecialForms {
    public static function builtins() {
        var map:Map<String, SpecialFormFunction> = [];

        function renameAndDeprecate(oldName:String, newName:String) {
            var form = map[oldName];
            map[oldName] = (wholeExp, args, k) -> {
                CompileError.warnFromExp(wholeExp, '$oldName has been renamed to $newName and deprecated');
                form(wholeExp, args, k);
            }
            map[newName] = form;
        }

        map["begin"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            // Sometimes empty blocks are useful, so a checkNumArgs() seems unnecessary here for now.

            // blocks can contain field forms that don't return an expression. These can't be included in blocks
            var exprs = [];
            for (bodyExp in args) {
                var expr = k.convert(bodyExp);
                if (expr != null) {
                    exprs.push(expr);
                }
            }
            EBlock(exprs).withMacroPosOf(wholeExp);
        };

        function arrayAccess(wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) {
            return EArray(k.convert(args[0]), k.convert(args[1])).withMacroPosOf(wholeExp);
        };
        map["nth"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, 2, "(nth [list] [idx])");
            arrayAccess(wholeExp, args, k);
        };
        map["dictGet"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, 2, "(dictGet [dict] [key])");
            arrayAccess(wholeExp, args, k);
        };

        function makeQuickNth(idx:Int, name:String) {
            map[name] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
                wholeExp.checkNumArgs(1, 1, '($name [list])');
                EArray(k.convert(args[0]), macro $v{idx}).withMacroPosOf(wholeExp);
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

        map["rest"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(1, 1, '(rest [list])');
            macro ${k.convert(args[0])}.slice(1);
        };

        // Declare anonymous objects
        map["object"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            if (args.length % 2 != 0) {
                throw CompileError.fromExp(wholeExp, "(object [field bindings]...) must have an even number of arguments");
            }
            EObjectDecl([
                for (pair in args.groups(2))
                    {
                        quotes: Unquoted,
                        field: switch (pair[0].def) {
                            case Symbol(name): name;
                            case TypedExp(_,
                                {pos: _, def: Symbol(_)}): throw CompileError.fromExp(pair[0], "type specification on anonymous objects will be ignored");
                            default: throw CompileError.fromExp(pair[0], "first expression in anonymous object field binding should be a plain symbol");
                        },
                        expr: k.convert(pair[1])
                    }
            ]).withMacroPosOf(wholeExp);
        };

        map["new"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(1, null, '(new [type] [constructorArgs...])');
            var classType = switch (args[0].def) {
                case Symbol(name): name;
                default: throw CompileError.fromExp(args[0], 'first arg in (new [type] ...) should be a class to instantiate');
            };
            ENew(Helpers.parseTypePath(classType, args[0]), args.slice(1).map(k.convert)).withMacroPosOf(wholeExp);
        };

        map["set"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, 2, "(set [variable] [value])");
            EBinop(OpAssign, k.convert(args[0]), k.convert(args[1])).withMacroPosOf(wholeExp);
        };

        function varName(nameExp:ReaderExp) {
            return switch (nameExp.def) {
                case Symbol(name) | TypedExp(_, {pos: _, def: Symbol(name)}):
                    name;
                case KeyValueExp(_, valueNameExp):
                    varName(valueNameExp);
                default:
                    throw CompileError.fromExp(nameExp, 'expected a symbol, typed symbol, or keyed symbol for variable name in a var binding');
            };
        }

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
                name: varName(nameExp),
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
                        var uniqueVarName = "_" + Uuid.v4().toShort();
                        var uniqueVarSymbol = Symbol(uniqueVarName).withPosOf(valueExp);
                        var idx = 0;
                        // Only evaluate the list expression being destructured once:
                        [toVar(uniqueVarSymbol, valueExp, k, true)].concat([
                            for (nameExp in nameExps)
                                toVar(nameExp, switch (nameExp.def) {
                                    case KeyValueExp(keyExp, nameExp):
                                        CallExp(Symbol("dictGet").withPosOf(valueExp), [uniqueVarSymbol, keyExp]).withPosOf(valueExp);
                                    default:
                                        CallExp(Symbol("nth").withPosOf(valueExp),
                                            [uniqueVarSymbol, Symbol(Std.string(idx++)).withPosOf(valueExp)]).withPosOf(valueExp);
                                }, k, if (isFinal == false) false else null)
                        ]);
                    default:
                        throw CompileError.fromExp(namesExp, "Can only bind variables to a symbol or list of symbols for destructuring");
                };
            };
        }

        map["deflocal"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, 3, "(localVar [optional :type] [variable] [optional: &mut] [value])");
            EVars(toVars(args[0], args[1], k)).withMacroPosOf(wholeExp);
        };
        renameAndDeprecate("deflocal", "localVar");

        map["let"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, null, "(let [[bindings...]] [body...])");
            var bindingList = args[0].bindingList("let");
            var bindingPairs = bindingList.groups(2);
            var varDefs = [];
            for (bindingPair in bindingPairs) {
                varDefs = varDefs.concat(toVars(bindingPair[0], bindingPair[1], k));
            }

            var body = args.slice(1);
            if (body.length == 0) {
                throw CompileError.fromArgs(args, '(let....) expression needs a body');
            }

            EBlock([
                EVars(varDefs).withMacroPosOf(wholeExp),
                EBlock(body.map(k.convert)).withMacroPosOf(wholeExp)
            ]).withMacroPosOf(wholeExp);
        };

        map["lambda"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, null, "(lambda [[argsNames...]] [body...])");
            var returnsValue = switch (args[0].def) {
                case TypedExp("Void", argNames):
                    args[0] = argNames;
                    false;
                default:
                    true;
            }
            EFunction(FAnonymous, Helpers.makeFunction(null, returnsValue, args[0], args.slice(1), k, "lambda")).withMacroPosOf(wholeExp);
        };

        function forExpr(formName:String, wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) {
            wholeExp.checkNumArgs(3, null, '($formName [varName or [varNames...] or =>keyName valueName] [list] [body...])');
            var uniqueVarName = "_" + Uuid.v4().toShort();
            var namesExp = args[0];
            var listExp = args[1];
            var bodyExps = args.slice(2);

            var loopVarExpr:Expr = switch (namesExp.def) {
                case KeyValueExp(_, _): k.convert(namesExp);
                default: {
                        bodyExps.insert(0,
                            CallExp(Symbol("localVar").withPosOf(args[2]), [namesExp, Symbol(uniqueVarName).withPosOf(args[2])]).withPosOf(args[2]));
                        macro $i{uniqueVarName};
                    }
            };

            var body = CallExp(Symbol("begin").withPosOf(args[2]), bodyExps).withPosOf(args[2]);
            return EFor(EBinop(OpIn, loopVarExpr, k.convert(listExp)).withMacroPosOf(wholeExp), k.convert(body)).withMacroPosOf(wholeExp);
        }

        map["doFor"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            EBlock([forExpr("doFor", wholeExp, args, k), macro null]).withMacroPosOf(wholeExp);
        };
        map["for"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            EArrayDecl([forExpr("for", wholeExp, args, k)]).withMacroPosOf(wholeExp);
        };

        map["loop"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(1, null, '(loop [body...])');
            EWhile(macro true, k.convert(wholeExp.expBuilder().begin(args)), true).withMacroPosOf(wholeExp);
        };

        map["return"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(0, 1, '(return [?value])');
            var returnExpr = if (args.length == 1) k.convert(args[0]) else null;
            EReturn(returnExpr).withMacroPosOf(wholeExp);
        };

        map["break"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(0, 0, "(break)");
            EBreak.withMacroPosOf(wholeExp);
        };

        map["continue"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(0, 0, "(continue)");
            EContinue.withMacroPosOf(wholeExp);
        };

        // (case... ) for switch
        map["case"] = (wholeExp:ReaderExp, args:kiss.List<ReaderExp>, k:KissState) -> {
            // Most Lisps don't enforce covering all possible patterns with (case...), but Kiss does,
            // because pattern coverage is a useful feature of Haxe that Kiss can easily bring along.
            // To be more similar to other Lisps, Kiss *could* generate a default case that returns null
            // if no "otherwise" clause is given.

            // Therefore only one case is required in a case statement, because one case could be enough
            // to cover all patterns.
            wholeExp.checkNumArgs(2, null, '(case [expression] [cases...] [optional: (otherwise [default])])');
            var b = wholeExp.expBuilder();
            var defaultExpr = switch (args[-1].def) {
                case CallExp({pos: _, def: Symbol("otherwise")}, otherwiseExps):
                    args.pop();
                    k.convert(b.begin(otherwiseExps));
                default:
                    null;
            };
            ESwitch(k.withoutListWrapping().convert(args[0]), args.slice(1).map(Helpers.makeSwitchCase.bind(_, k)), defaultExpr).withMacroPosOf(wholeExp);
        };

        // Type check syntax:
        map["the"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(2, 3, '(the <?package> <type> <value>)');
            var pkg = "";
            var whichArg = "first";
            if (args.length == 3) {
                pkg = switch (args.shift().def) {
                    case Symbol(pkg): pkg;
                    default: throw CompileError.fromExp(args[0], '$whichArg argument to (the... ) should be a valid haxe package');
                };
                whichArg = "second";
            }
            var type = switch (args[0].def) {
                case Symbol(type): type;
                default: throw CompileError.fromExp(args[0], '$whichArg argument to (the... ) should be a valid type');
            };
            if (pkg.length > 0)
                type = pkg + "." + type;
            ECheckType(k.convert(args[1]), Helpers.parseComplexType(type, args[0])).withMacroPosOf(wholeExp);
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
            ]).withMacroPosOf(wholeExp);
        };

        map["throw"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            if (args.length != 1) {
                throw CompileError.fromExp(wholeExp, 'throw expression should only throw one value');
            }
            EThrow(k.convert(args[0])).withMacroPosOf(wholeExp);
        };

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
            wholeExp.checkNumArgs(1, 1, '(not [value])');
            var condition = k.convert(args[0]);
            var truthyExp = macro Prelude.truthy($condition);
            macro !$truthyExp;
        };

        map["cast"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(1, 2, '(cast <value> <optional type>)');
            var e = k.convert(args[0]);
            var t = null;
            if (args.length > 1) {
                switch (args[1].def) {
                    case Symbol(typePath):
                        t = Helpers.parseComplexType(typePath, args[1]);
                    default:
                        throw CompileError.fromExp(args[1], 'second argument to cast should be a type path symbol');
                }
            }
            ECast(e, t).withMacroPosOf(wholeExp);
        }

        return map;
    }

    public static function caseOr(wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState):Expr {
        wholeExp.checkNumArgs(2, null, "(or [v1] [v2] [values...])");
        return if (args.length == 2) {
            macro ${k.convert(args[0])} | ${k.convert(args[1])};
        } else {
            macro ${k.convert(args[0])} | ${caseOr(wholeExp, args.slice(1), k)};
        };
    };

    public static function caseAs(wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState):Expr {
        wholeExp.checkNumArgs(2, 2, "(as [name] [pattern])");
        return macro ${k.convert(args[0])} = ${k.convert(args[1])};
    };
}
