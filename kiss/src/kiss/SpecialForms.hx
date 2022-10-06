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
using tink.MacroApi;
import tink.syntaxhub.*;

// Special forms convert Kiss reader expressions into Haxe macro expressions
typedef SpecialFormFunction = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> Expr;

class SpecialForms {
    public static function builtins(k:KissState, ?context:FrontendContext) {
        var map:Map<String, SpecialFormFunction> = [];

        function renameAndDeprecate(oldName:String, newName:String) {
            var form = map[oldName];
            map[oldName] = (wholeExp, args, k) -> {
                KissError.warnFromExp(wholeExp, '$oldName has been renamed to $newName and deprecated');
                form(wholeExp, args, k);
            }
            map[newName] = form;
            k.formDocs[newName] = k.formDocs[oldName];
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
            var exp = k.convert(args[0]);
            for (dimension in 1...args.length) {
                exp = EArray(exp, k.convert(args[dimension])).withMacroPosOf(wholeExp);
            }
            return exp;
        };
        k.doc("nth", 2, null, "(nth <list> <idx> <?n-dimensional indices...>)");
        map["nth"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            arrayAccess(wholeExp, args, k);
        };
        k.doc("dictGet", 2, 2, "(dictGet <dict> <key>)");
        map["dictGet"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            arrayAccess(wholeExp, args, k);
        };

        function makeQuickNth(idx:Int, name:String) {
            k.doc(name, 1, 1, '($name <list>)');
            map[name] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
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

        k.doc("rest", 1, 1, '(rest <list>)');
        map["rest"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var m = macro ${k.convert(args[0])}.slice(1);
            wholeExp.expBuilder().haxeExpr(m);
        };

        // Declare anonymous objects
        map["object"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            if (args.length % 2 != 0) {
                throw KissError.fromExp(wholeExp, "(object [field bindings]...) must have an even number of arguments");
            }
            EObjectDecl([
                for (pair in args.groups(2))
                    {
                        quotes: Unquoted,
                        field: switch (pair[0].def) {
                            case Symbol(name): name;
                            case TypedExp(_,
                                {pos: _, def: Symbol(_)}): throw KissError.fromExp(pair[0], "type specification on anonymous objects will be ignored");
                            default: throw KissError.fromExp(pair[0], "first expression in anonymous object field binding should be a plain symbol");
                        },
                        expr: k.convert(pair[1])
                    }
            ]).withMacroPosOf(wholeExp);
        };

        k.doc("new", 1, null, '(new <type> <constructorArgs...>)');
        map["new"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var classType = switch (args[0].def) {
                case Symbol(name): name;
                default: throw KissError.fromExp(args[0], 'first arg in (new [type] ...) should be a class to instantiate');
            };
            ENew(Helpers.parseTypePath(classType, args[0]), args.slice(1).map(k.convert)).withMacroPosOf(wholeExp);
        };

        k.doc("set", 2, 2, "(set <variable> <value>)");
        map["set"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            EBinop(OpAssign, k.convert(args[0]), k.convert(args[1])).withMacroPosOf(wholeExp);
        };

        function varName(nameExp:ReaderExp) {
            return switch (nameExp.def) {
                case Symbol(name) | TypedExp(_, {pos: _, def: Symbol(name)}):
                    name;
                case KeyValueExp(_, valueNameExp):
                    varName(valueNameExp);
                default:
                    throw KissError.fromExp(nameExp, 'expected a symbol, typed symbol, or keyed symbol for variable name in a var binding');
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
                        throw KissError.fromExp(namesExp, "Can only bind variables to a symbol or list of symbols for destructuring");
                };
            };
        }

        k.doc("deflocal", 2, 3, "(localVar <optional :type> <variable> <optional: &mut> <value>)");
        map["deflocal"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            EVars(toVars(args[0], args[1], k)).withMacroPosOf(wholeExp);
        };
        renameAndDeprecate("deflocal", "localVar");

        k.doc("let", 2, null, "(let [<bindings...>] <body...>)");
        map["let"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var bindingList = args[0].bindingList("let");
            var bindingPairs = bindingList.groups(2);
            var varDefs = [];
            for (bindingPair in bindingPairs) {
                varDefs = varDefs.concat(toVars(bindingPair[0], bindingPair[1], k));
            }

            var body = args.slice(1);
            if (body.length == 0) {
                throw KissError.fromArgs(args, '(let....) expression needs a body');
            }

            for (v in varDefs) {
                k.addVarInScope(v, true);
            }

            var block = EBlock([
                EVars(varDefs).withMacroPosOf(wholeExp),
                EBlock(body.map(k.convert)).withMacroPosOf(wholeExp)
            ]).withMacroPosOf(wholeExp);

            for (v in varDefs) {
                k.removeVarInScope(v, true);
            }

            block;
        };

        k.doc("lambda", 2, null, "(lambda [<argsNames...>] <body...>)");
        map["lambda"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var returnsValue = switch (args[0].def) {
                case TypedExp("Void", argNames):
                    args[0] = argNames;
                    false;
                default:
                    true;
            }
            EFunction(FAnonymous, Helpers.makeFunction(null, returnsValue, args[0], args.slice(1), k, "lambda", [])).withMacroPosOf(wholeExp);
        };
        
        k.doc("localFunction", 3, null, "(localFunction <optional :Type> <name> [<args...>] <body...>)");
        map["localFunction"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var name = "";
            var returnsValue = switch (args[0].def) {
                case TypedExp("Void", {pos:_, def: Symbol(fname)}):
                    name = fname;
                    false;
                case Symbol(fname):
                    name = fname;
                    true;
                default:
                    throw KissError.fromExp(wholeExp, "First argument to localFunction must be a function name with an optional return type. To make an anonymous function, use lambda instead.");
            }
            EFunction(FNamed(name, false), Helpers.makeFunction(null, returnsValue, args[1], args.slice(2), k, "localFunction", [])).withMacroPosOf(wholeExp);
        };
    
        function forExpr(formName:String, wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) {
            var uniqueVarName = "_" + Uuid.v4().toShort();
            var namesExp = args[0];
            var listExp = args[1];
            var bodyExps = args.slice(2);
            
            var b = wholeExp.expBuilder();
            var m = macro $i{uniqueVarName};

            var loopVarExpr:Expr = switch (namesExp.def) {
                case KeyValueExp(_, _): k.convert(namesExp);
                default: {
                        bodyExps.insert(0,
                            CallExp(Symbol("localVar").withPosOf(args[2]), [namesExp, Symbol(uniqueVarName).withPosOf(args[2])]).withPosOf(args[2]));
                        b.haxeExpr(m);
                    }
            };

            var body = CallExp(Symbol("begin").withPosOf(args[2]), bodyExps).withPosOf(args[2]);
            return EFor(EBinop(OpIn, loopVarExpr, k.convert(listExp)).withMacroPosOf(wholeExp), k.convert(body)).withMacroPosOf(wholeExp);
        }

        k.doc("doFor", 3, null, '(doFor <var> <iterable> <body...>)');
        k.doc("for", 3, null, '(for <var> <iterable> <body...>)');
        map["doFor"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            EBlock([forExpr("doFor", wholeExp, args, k), k.convert(wholeExp.expBuilder().symbol("null"))]).withMacroPosOf(wholeExp);
        };
        map["for"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            EArrayDecl([forExpr("for", wholeExp, args, k)]).withMacroPosOf(wholeExp);
        };

        k.doc("loop", 1, null, '(loop <body...>)');
        map["loop"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            EWhile(macro true, k.convert(wholeExp.expBuilder().begin(args)), true).withMacroPosOf(wholeExp);
        };

        
        function whileForm(invert:Bool, wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) {
            var funcName = if (invert) "until" else "while";
            var b = wholeExp.expBuilder();
            var cond = k.convert(b.callSymbol("Prelude.truthy", [args[0]]));
            if (invert) {
                cond = macro !$cond;
                cond = b.haxeExpr(cond);
            }
            return EWhile(cond, k.convert(b.begin(args)), true).withMacroPosOf(wholeExp);
        }

        k.doc("while", 2, null, '(while <condition> <body...>)');
        map["while"] = whileForm.bind(false);
        k.doc("until", 2, null, '(until <condition> <body...>)');
        map["until"] = whileForm.bind(true);

        k.doc("return", 0, 1, '(return <?value>)');
        map["return"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {    
            var returnExpr = if (args.length == 1) k.convert(args[0]) else null;
            EReturn(returnExpr).withMacroPosOf(wholeExp);
        };
        
        k.doc("break", 0, 0, "(break)");
        map["break"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {   
            EBreak.withMacroPosOf(wholeExp);
        };

        k.doc("continue", 0, 0, "(continue)");
        map["continue"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            EContinue.withMacroPosOf(wholeExp);
        };

        // (case... ) for switch
        k.doc("case", 2, null, '(case <expression> <cases...> <optional: (otherwise <default>)>)');
        map["case"] = (wholeExp:ReaderExp, args:kiss.List<ReaderExp>, k:KissState) -> {
            // Most Lisps don't enforce covering all possible patterns with (case...), but Kiss does,
            // because pattern coverage is a useful feature of Haxe that Kiss can easily bring along.
            // To be more similar to other Lisps, Kiss *could* generate a default case that returns null
            // if no "otherwise" clause is given.

            // Therefore only one case is required in a case statement, because one case could be enough
            // to cover all patterns.
            var args:kiss.List<ReaderExp> = args.copy();

            var cases:kiss.List<ReaderExp> = args.slice(1);
            for (i in 0...cases.length) {
                switch (cases[i].def) {
                    case CallExp({pos: _, def: Symbol("never")}, neverExps):
                        cases[i].checkNumArgs(1, 1, '(never <pattern>)');
                        var b = cases[i].expBuilder();    
                        var failureError = KissError.fromExp(cases[i], '').toString(AssertionFail);
                        var colonsInPrefix = if (Sys.systemName() == "Windows") 5 else 4;
                        cases[i] = b.call(neverExps[0], [
                            b.callSymbol('throw', [
                                b.callSymbol('kiss.Prelude.runtimeInsertAssertionMessage', [b.str('${Reader.toString(neverExps[0].def)} should never match pattern ${Reader.toString(neverExps[0].def)}'), b.str(failureError), b.int(colonsInPrefix)])])]);
                    case CallExp({pos: _, def: Symbol("otherwise")}, _) if (i != cases.length - 1):
                        throw KissError.fromExp(cases[i], "(otherwise <body...>) branch must come last in a (case <...>) expression");
                    default:
                }
            }

            var isTupleCase = switch (args[0].def) {
                case ListExp(_):
                    true;
                default:
                    false;
            }

            var b = wholeExp.expBuilder();
            var defaultExpr = switch (cases[-1].def) {
                case CallExp({pos: _, def: Symbol("otherwise")}, otherwiseExps):
                    cases.pop();
                    k.convert(b.begin(otherwiseExps));
                default:
                    null;
            };

            var exp = k.withoutListWrapping().convert(args[0]);

            var canCompareNull = !isTupleCase;

            
            // case also override's haxe's switch() behavior by refusing to match null values against <var> patterns.
            if (canCompareNull) {
                var nullExpr = defaultExpr;
                var idx = 0;
                for (arg in cases) {
                    switch (arg.def) {
                        case CallExp({pos: _, def: Symbol("null")}, nullExps):
                            cases.splice(idx, 1);
                            nullExpr = k.convert(b.begin(nullExps));
                            break;
                        default:
                    }
                    ++idx;
                }

                if (nullExpr == null) {
                    throw KissError.fromExp(wholeExp, "Unmatched pattern: null");
                }

                var nullCase = if (k.hscript) {
                    b.callSymbol("null", [b.raw(nullExpr.toString())]);  
                } else {
                    var gensym = b.symbol();
                    b.call(b.callSymbol("when", [b.callSymbol("Prelude.isNull", [gensym]), gensym]), [b.raw(nullExpr.toString())]);
                };

                cases.insert(0, nullCase);
            }

            ESwitch(exp, cases.map(Helpers.makeSwitchCase.bind(_, k)), defaultExpr).withMacroPosOf(wholeExp);
        };

        // Type check syntax:
        k.doc("the", 2, 3, '(the <?package> <type> <value>)');
        map["the"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var pkg = "";
            var whichArg = "first";
            if (args.length == 3) {
                pkg = switch (args.shift().def) {
                    case Symbol(pkg): pkg;
                    default: throw KissError.fromExp(args[0], '$whichArg argument to (the... ) should be a valid haxe package');
                };
                whichArg = "second";
            }
            var type = switch (args[0].def) {
                case Symbol(type): type;
                default: throw KissError.fromExp(args[0], '$whichArg argument to (the... ) should be a valid type');
            };
            if (pkg.length > 0)
                type = pkg + "." + type;
            ECheckType(k.convert(args[1]), Helpers.parseComplexType(type, args[0])).withMacroPosOf(wholeExp);
        };

        k.doc("try", 1, null, "(try <thing> <catches...>)");
        map["try"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
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
                                    default: throw KissError.fromExp(catchArgs[0], 'first argument to (catch... ) should be a one-element argument list');
                                },
                                type: switch (catchArgs[0].def) {
                                    case ListExp([{pos: _, def: TypedExp(type, _)}]):
                                        Helpers.parseComplexType(type, catchArgs[0]);
                                    default: null;
                                },
                                expr: k.convert(CallExp(Symbol("begin").withPos(catchArgs[1].pos), catchArgs.slice(1)).withPos(catchArgs[1].pos))
                            };
                        default:
                            throw KissError.fromExp(catchKissExp,
                                'expressions following the first expression in a (try... ) should all be (catch [[error]] [body...]) expressions');
                    }
                }
            ]).withMacroPosOf(wholeExp);
        };

        map["throw"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            if (args.length != 1) {
                throw KissError.fromExp(wholeExp, 'throw expression should only throw one value');
            }
            EThrow(k.convert(args[0])).withMacroPosOf(wholeExp);
        };

        k.doc("if", 2, 3, '(if <cond> <then> <?else>)');
        map["if"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            var condition = macro Prelude.truthy(${k.convert(args[0])});
            var thenExp = k.convert(args[1]);
            var elseExp = if (args.length > 2) {
                k.convert(args[2]);
            } else {
                // Kiss (if... ) expressions all need to generate a Haxe else block
                // to make sure they always return something
                k.convert(b.symbol("null"));
            };

            // TODO these macro forms cause the compiler errors to give line numbers
            // pointing back to SpecialForms.hx, which aren't helpful. withMacroPosOf should be used
            // to wrap them
            var m = macro if ($condition)
                $thenExp
            else
                $elseExp;

            b.haxeExpr(m);
        };

        k.doc("not", 1, 1, '(not <value>)');
        map["not"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            var condition = k.convert(args[0]);
            var truthyExp = macro Prelude.truthy($condition);
            var m = macro !$truthyExp;
            b.haxeExpr(m);
        };

        k.doc("cast", 1, 2, '(cast <value> <optional type>)');
        map["cast"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var e = k.convert(args[0]);
            var t = null;
            if (args.length > 1) {
                switch (args[1].def) {
                    case Symbol(typePath):
                        t = Helpers.parseComplexType(typePath, args[1]);
                    default:
                        throw KissError.fromExp(args[1], 'second argument to cast should be a type path symbol');
                }
            }
            ECast(e, t).withMacroPosOf(wholeExp);
        }

        k.doc("trace", 1, 2, "(trace <value> <?label>)");
        map["trace"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            var label = if (exps.length > 1) exps[1] else b.str("");
            var label = k.convert(label);
            var m = macro kiss.Prelude.withLabel(v, $label);
            EBlock([
                EVars([
                    toVar(b.symbol("v"), exps[0], k)
                ]).withMacroPosOf(wholeExp),
                ECall(EConst(CIdent("trace")).withMacroPosOf(wholeExp), [
                    b.haxeExpr(m)
                ]).withMacroPosOf(wholeExp),
                k.convert(exps[0])
            ]).withMacroPosOf(wholeExp);
        };

        k.doc("macroPrint", 1, 1, "(macroPrint <exp...>)");
        // At compile-time, print the macro expansion and generated haxe code of the given expression,
        // Then at runtime, evaluate the expression normally.
        map["macroPrint"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            Helpers.printExp(exps[0]);

            var e = Kiss.convert(k, exps[0]);
            Prelude.printStr(e.toString());
            return e;
        };

        function requireContext(exp, formName) {
            if (context == null) {
                throw KissError.fromExp(exp, '$formName cannot be used when calling Kiss as a build macro in a Haxe file.');
            }
        }

        function none(exp) {
            return EBlock([]).withMacroPosOf(exp);
        }

		k.doc("import", 1, null, "(import <types...>)");
        map["import"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            requireContext(wholeExp, "import");
            for (type in exps) {
                context.addImport(Reader.toString(type.def), INormal, wholeExp.macroPos());
            }
            return none(wholeExp);
        };

        k.doc("importAs", 2, 2, "(importAs <Type> <Alias>)");
        map["importAs"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            requireContext(wholeExp, "importAs");
            context.addImport(Reader.toString(exps[0].def), IAsName(Reader.toString(exps[1].def)), wholeExp.macroPos());
            return none(wholeExp);
        };

        k.doc("importAll", 1, 1, "(importAll <package>)");
        map["importAll"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            requireContext(wholeExp, "importAll");
            context.addImport(Reader.toString(exps[0].def), IAll, wholeExp.macroPos());
            return none(wholeExp);
        };
        
        k.doc("using", 1, null, "(using <Types...>)");
        map["using"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            requireContext(wholeExp, "using");
            for (type in exps) {
                context.addUsing(Reader.toString(type.def), wholeExp.macroPos());
            }
            return none(wholeExp);
        };

        k.doc("extends", 1, 1, "(extends <Class>)");
        map["extends"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            requireContext(wholeExp, "extends");
            var type = context.getType();
            type.kind = switch (type.kind) {
                case TDClass(null, interfaces, false, false, false):
                    TDClass(Reader.toString(exps[0].def).asTypePath(), interfaces, false, false, false);
                default:
                    throw KissError.fromExp(wholeExp, '${type.name} must be a class without a superclass');
            }
            return none(wholeExp);
        };

        k.doc("implements", 1, null, "(implements <Interfaces...>)");
        map["implements"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            requireContext(wholeExp, "implements");
            var type = context.getType();
            var interfaces = [for (exp in exps) Reader.toString(exp.def).asTypePath()];
            type.kind = switch (type.kind) {
                case TDClass(superClass, [], false, false, false):
                    TDClass(superClass, interfaces, false, false, false);
                default:
                    throw KissError.fromExp(wholeExp, '${type.name} must be a class without any interfaces');
            }
            return none(wholeExp);
        };

        return map;
    }
    
    public static function caseOr(wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState):Expr {
        wholeExp.checkNumArgs(2, null, "(or <pattern1> <pattern2> <patterns...>)");
        var b = wholeExp.expBuilder();
        return if (args.length == 2) {
            var m = macro ${k.convert(args[0])} | ${k.convert(args[1])};
            b.haxeExpr(m);
        } else {
            var m = macro ${k.convert(args[0])} | ${caseOr(wholeExp, args.slice(1), k)};
            b.haxeExpr(m);
        };
    };

    public static function caseAs(wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState):Expr {
        wholeExp.checkNumArgs(2, 2, "(as <name> <pattern>)");
        var b = wholeExp.expBuilder();
        var m = macro ${k.convert(args[0])} = ${k.convert(args[1])};
        return b.haxeExpr(m);
    };
}
