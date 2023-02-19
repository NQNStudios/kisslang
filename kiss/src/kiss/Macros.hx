package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import kiss.Reader;
import kiss.ReaderExp;
import kiss.Kiss;
import kiss.KissError;
import kiss.CompilerTools;
import uuid.Uuid;
import hscript.Parser;
import haxe.EnumTools;

using kiss.Kiss;
using kiss.Prelude;
using kiss.Reader;
using kiss.Helpers;
using StringTools;
using tink.MacroApi;

// Macros generate new Kiss reader expressions from the arguments of their call expression.
typedef MacroFunction = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> Null<ReaderExp>;

class Macros {
    public static function builtins(k:KissState) {
        var macros:Map<String, MacroFunction> = [];

        function renameAndDeprecate(oldName:String, newName:String) {
            var form = macros[oldName];
            macros[oldName] = (wholeExp, args, k) -> {
                KissError.warnFromExp(wholeExp, '$oldName has been renamed to $newName and deprecated');
                form(wholeExp, args, k);
            }
            macros[newName] = form;
            k.formDocs[newName] = k.formDocs[oldName];
        }

        function compileTimeResolveToString(description:String, description2:String, exp:ReaderExp, k:KissState):String {
            switch (exp.def) {
                case StrExp(str):
                    return str;
                case CallExp({pos: _, def: Symbol(mac)}, innerArgs) if (macros.exists(mac)):
                    var docs = k.formDocs[mac];
                    exp.checkNumArgs(docs.minArgs, docs.maxArgs, docs.expectedForm);
                    return compileTimeResolveToString(description, description2, macros[mac](exp, innerArgs, k), k);
                default:
                    throw KissError.fromExp(exp, '${description} should resolve at compile-time to a string literal of ${description2}');
            }
        }

        k.doc("load", 1, 1, '(load "<file.kiss>")');
        macros["load"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            Kiss.load(compileTimeResolveToString("The only argument to (load...)", "a .kiss file path", args[0], k), k);
        };

        k.doc("loadFrom", 2, 2, '(loadFrom "<haxelib name>" "<file.kiss>")');
        macros["loadFrom"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var libName = compileTimeResolveToString("The first argument to (loadFrom...)", "a haxe library's name", args[0], k);
            var libPath = Prelude.libPath(libName);
            var otherKissFile = compileTimeResolveToString("The second argument to (loadFrom...)", "a .kiss file path", args[1], k);
            Kiss.load(otherKissFile, k, libPath);
        };

        function destructiveVersion(op:String, assignOp:String) {
            k.doc(assignOp, 2, null, '($assignOp <var> <v1> <values...>)');
            macros[assignOp] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k) -> {
                var b = wholeExp.expBuilder();
                b.call(
                    b.symbol("set"), [
                        exps[0],
                        b.call(
                            b.symbol(op),
                            exps)
                    ]);
            };
        }

        destructiveVersion("%", "%=");
        destructiveVersion("^", "^=");
        destructiveVersion("+", "+=");
        destructiveVersion("-", "-=");
        destructiveVersion("*", "*=");
        destructiveVersion("/", "/=");

        var opAliases = [
            // These shouldn't be ident aliases because they are common variable names
            "min" => "Prelude.min",
            "max" => "Prelude.max",
            // These might not be common, but playing it safe:
            "iHalf" => "Prelude.iHalf",
            "iThird" => "Prelude.iThird",
            "iFourth" => "Prelude.iFourth",
            "iFifth" => "Prelude.iFifth",
            "iSixth" => "Prelude.iSixth",
            "iSeventh" => "Prelude.iSeventh",
            "iEighth" => "Prelude.iEighth",
            "iNinth" => "Prelude.iNinth",
            "iTenth" => "Prelude.iTenth",
            "fHalf" => "Prelude.fHalf",
            "fThird" => "Prelude.fThird",
            "fFourth" => "Prelude.fFourth",
            "fFifth" => "Prelude.fFifth",
            "fSixth" => "Prelude.fSixth",
            "fSeventh" => "Prelude.fSeventh",
            "fEighth" => "Prelude.fEighth",
            "fNinth" => "Prelude.fNinth",
            "fTenth" => "Prelude.fTenth",
            // These can't be ident aliases because they would supercede the typed call macros that wrap them:
            "zip" => "Prelude.zipThrow",
            "zipThrow" => "Prelude.zipThrow",
            "zipKeep" => "Prelude.zipKeep",
            "zipDrop" => "Prelude.zipDrop",
            "concat" => "Prelude.concat",
            "intersect" => "Prelude.intersect",
            "and" => "Prelude.and",
            "or" => "Prelude.or"
        ];
        k.doc("apply", 2, 2, '(apply <func> <argList>)' );
        macros["apply"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k) -> {
            var b = wholeExp.expBuilder();
            var callOn = switch (exps[0].def) {
                case FieldExp(field, exp):
                    exp;
                default:
                    b.symbol("null");
            };
            var func = switch (exps[0].def) {
                case Symbol(func) if (opAliases.exists(func)):
                    b.symbol(opAliases[func]);
                default:
                    exps[0];
            };
            var args = exps[1];
            b.call(
                b.symbol("Reflect.callMethod"), [
                    callOn, func, args
                ]);
        };

        k.doc("range", 1, 3, '(range <?min> <max> <?step>)');
        macros["range"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k) -> {
            var b = wholeExp.expBuilder();
            var min = if (exps.length > 1) exps[0] else b.symbol("0");
            var max = if (exps.length > 1) exps[1] else exps[0];
            var step = if (exps.length > 2) exps[2] else b.symbol("1");
            b.callSymbol("Prelude.range", [min, max, step]);
        };

        function prepareForConditional(i:KissInterp, k:KissState) {
            i.variables.set("kissFile", k.file);
            i.variables.set("className", k.className);
            for (flag => value in Context.getDefines()) {
                // Don't overwrite types that are put in all KissInterps, i.e. the kiss namespace
                if (!i.variables.exists(flag)) {
                    i.variables.set(flag, value);
                }
            }
           for (macroVar => value in k.macroVars) {
                // Don't overwrite types that are put in all KissInterps, i.e. the kiss namespace
                if (!i.variables.exists(macroVar)) {
                    i.variables.set(macroVar, value);
                }
            }
        }

        // Most conditional compilation macros are based on this macro:
        k.doc("#if", 2, 3, '(#if <cond> <then> <?else>)' );
        macros["#if"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k) -> {
            var b = wholeExp.expBuilder();
            var conditionExp = exps.shift();
            var thenExp = exps.shift();
            var elseExp = if (exps.length > 0) exps.shift(); else b.none();

            var conditionInterp = new KissInterp(true);
            var conditionStr = Reader.toString(conditionExp.def);
            prepareForConditional(conditionInterp, k);
            try {
                var hscriptStr = Prelude.convertToHScript(conditionStr);
                // TODO are there more properties of target that need to be added?
                // Context.definedValue only returns a string so if there's a whole
                // object, I don't know how to get it
                conditionInterp.variables["target"] = {
                    threaded: Context.defined("target.threaded")
                };
                #if test
                Prelude.print("#if condition hscript: " + hscriptStr);
                #end
                return if (Prelude.truthy(conditionInterp.evalHaxe(hscriptStr))) {
                    #if test
                    Prelude.print("using thenExp");
                    #end
                    thenExp;
                } else {
                    #if test
                    Prelude.print("using elseExp");
                    #end
                    elseExp;
                }
            } catch (e) {
                throw KissError.fromExp(conditionExp, 'condition for #if threw error $e');
            }
        };

        // But not this one:
        k.doc("#case", 2, null, '(#case <expression> <cases...> <optional: (otherwise <default>)>)');
        macros["#case"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k) -> {
            var b = wholeExp.expBuilder();
            var caseVar = exps.shift();
            var matchPatterns = [];
            var matchBodies = [];
            var matchBodySymbols = [];
            var caseArgs = [caseVar];
            for (exp in exps) {
                switch (exp.def) {
                    case CallExp(pattern, bodyExps):
                        matchPatterns.push(pattern);
                        matchBodies.push(b.begin(bodyExps));
                        var gensym = b.symbol();
                        matchBodySymbols.push(gensym);
                        caseArgs.push(b.call(pattern, [gensym]));
                    default:
                        throw KissError.fromExp(exp, "invalid pattern expression for #case");
                }
            }

            var caseExp = b.callSymbol("case", caseArgs);

            var caseInterp = new KissInterp();
            var caseStr = Reader.toString(caseExp.def);
            for (matchBodySymbol in matchBodySymbols) {
                caseInterp.variables.set(Prelude.symbolNameValue(matchBodySymbol), matchBodies.shift());
            }
            prepareForConditional(caseInterp, k);
            try {
                var hscriptStr = Prelude.convertToHScript(caseStr);
                #if test
                Prelude.print("#case hscript: " + hscriptStr);
                #end
                return caseInterp.evalHaxe(hscriptStr);
            } catch (e) {
                throw KissError.fromExp(caseExp, '#case evaluation threw error $e');
            }
        }

        function addBodyIf(keywordName:String, underlyingIf:String, negated:Bool) {
            k.doc(keywordName, 2, null, '($keywordName <condition> <body...>)');
            macros[keywordName] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k) -> {
                var b = wholeExp.expBuilder();
                var condition = if (negated) {
                    b.call(
                        b.symbol("not"), [
                            args[0]
                        ]);
                } else {
                    args[0];
                }
                return b.call(b.symbol(underlyingIf), [
                    condition,
                    b.begin(args.slice(1))
                ]);
            };
        }
        addBodyIf("when", "if", false);
        addBodyIf("unless", "if", true);
        addBodyIf("#when", "#if", false);
        addBodyIf("#unless", "#if", true);
        
        addCond(k, macros, "cond", "if");
        addCond(k, macros, "#cond", "#if");

        k.doc("#value", 1, 1, '(#value "<name>")');
        macros["#value"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            b.str(Context.definedValue(compileTimeResolveToString("The only argument to (#value...)", "a compiler flag's name", args[0], k)));
        };
        
        k.doc("#symbol", 1, 1, '(#symbol "<name>")');
        macros["#symbol"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            b.symbol(Context.definedValue(compileTimeResolveToString("The only argument to (#symbol...)", "a compiler flag's name", args[0], k)));
        };

        k.doc("or", 1, null, "(or <v1> <values...>)");
        function _or(wholeExp:ReaderExp, args:Array<ReaderExp>, k) {
            var b = wholeExp.expBuilder();

            var uniqueVarSymbol = b.symbol();
            var firstVal = args.shift();

            var body = if (args.length > 0) {
                [
                    b.callSymbol("if", [uniqueVarSymbol, uniqueVarSymbol, _or(wholeExp, args, k)])
                ];
            } else {
                // If nothing is truthy, return the last one
                [uniqueVarSymbol];
            };

            return b.let([b.typed("Dynamic", uniqueVarSymbol), firstVal], body);
        };
       

        macros["or"] = _or;

        k.doc("and", 1, null, "(and <v1> <values...>)");
        function _and(wholeExp:ReaderExp, args:Array<ReaderExp>, k) {
            var b = wholeExp.expBuilder();
            var uniqueVarSymbol = b.symbol();
            var firstVal = args.shift();

            var body = if (args.length > 0) {
                [
                    b.callSymbol("if", [uniqueVarSymbol, _and(wholeExp, args, k), uniqueVarSymbol])
                ];
            } else {
                // If nothing is truthy, return the last one
                [uniqueVarSymbol];
            };

            return b.let([b.typed("Dynamic", uniqueVarSymbol), firstVal], body);

        }

        macros["and"] = _and;

        function arraySet(wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) {
            var b = wholeExp.expBuilder();
            var value = exps.pop();
            return b.call(
                b.symbol("set"), [
                    b.call(b.symbol("nth"), exps),
                    value
                ]);
        }
        k.doc("setNth", 3, null, "(setNth <list> <index> <?n-dimensional indices...> <value>)");
        macros["setNth"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            arraySet(wholeExp, exps, k);
        };
        k.doc("dictSet", 3, 3, "(dictSet <dict> <key> <value>)");
        macros["dictSet"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            arraySet(wholeExp, exps, k);
        };

        k.doc("assert", 1, 2, "(assert <expression> <?failure message>)");
        macros["assert"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            var expression = exps[0];
            
            var letVal = b.symbol();
            b.callSymbol("let", [
                b.list([
                    letVal,
                    expression
                ]),
                b.callSymbol("if", [
                    letVal,
                    letVal,
                    b.throwAssertionError()
                ])
            ]);
        };
        k.doc("assertThrows", 1, 2, "(assertThrows <expression> <?failure message>)");
        macros["assertThrows"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            var expression = exps[0];
            var basicMessage = '${expression.def.toString()} should have thrown an error';
            var messageExp = b.str(basicMessage);

            b.callSymbol("try", [
                b.begin([expression, b.callSymbol("throw", [messageExp])]),
                b.callSymbol("catch", [b.list([b.typed("Dynamic", b.symbol("error"))]),
                    b.callSymbol("if", [b.callSymbol("=", [b.symbol("error"), messageExp]),
                            b.throwAssertionError(),
                        b.symbol("true")])])
            ]);
        };

        k.doc("assertThrowsAtCompileTime", 1, 2, "(assertThrowsAtCompileTime <expression> <?failure message>)");
        macros["assertThrowsAtCompileTime"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            try {
                k.convert(exps[0]);
                b.throwAssertionError();
            } catch (e) {
                b.none();
            }
        };

        function stringsThatMatch(exp:ReaderExp, formName:String) {
            return switch (exp.def) {
                case StrExp(s):
                    [s];
                case ListExp(strings):
                    [
                        for (s in strings)
                            switch (s.def) {
                                case StrExp(s):
                                    s;
                                default:
                                    throw KissError.fromExp(s, 'initiator list of $formName must only contain strings');
                            }
                    ];
                default:
                    throw KissError.fromExp(exp, 'first argument to $formName should be a String or list of strings');
            };
        }
        
        k.doc("defmacro", 3, null, '(defMacro <name> [<args...>] <body...>)');
        macros["defmacro"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            k.stateChanged = true;
            var name = switch (exps[0].def) {
                case Symbol(name): name;
                default: throw KissError.fromExp(exps[0], "macro name should be a symbol");
            };

            var argList = switch (exps[1].def) {
                case ListExp(macroArgs): macroArgs;
                case CallExp(_, _):
                    throw KissError.fromExp(exps[1], 'expected a macro argument list. Change the parens () to brackets []');
                default:
                    throw KissError.fromExp(exps[1], 'expected a macro argument list');
            };

            // This is similar to &opt and &rest processing done by Helpers.makeFunction()
            // but combining them would probably make things less readable and harder
            // to maintain, because defmacro makes an actual function, not a function definition
            var minArgs = 0;
            var maxArgs = 0;
            // Once the &opt meta appears, all following arguments are optional until &rest
            var optIndex = -1;
            // Once the &rest or &body meta appears, no other arguments can be declared
            var restIndex = -1;
            var requireRest = false;
            var argNames = [];

            var macroCallForm = '($name';

            var builderName:String = null;
            for (arg in argList) {
                
                switch (arg.def) {
                    case MetaExp("builder", {pos: _, def: Symbol(name)}):
                        if (builderName == null) {
                            builderName = name;
                        } else {
                            throw KissError.fromExp(arg, 'Cannot declare multiple &builder args. Already declared: $builderName');
                        }
                    default:
                        if (restIndex != -1) {
                            throw KissError.fromExp(arg, "macros cannot declare arguments after a &rest or &body argument");
                        }
                        switch (arg.def) {
                            case Symbol(name):
                                argNames.push(name);
                                if (optIndex == -1) {
                                    ++minArgs;
                                    macroCallForm += ' <$name>';
                                } else {
                                    macroCallForm += ' <?$name>';
                                }
                                ++maxArgs;
                            
                            case MetaExp("opt", {pos: _, def: Symbol(name)}):
                                argNames.push(name);
                                macroCallForm += ' <?$name>';
                                optIndex = maxArgs;
                                ++maxArgs;
                            case MetaExp("rest", {pos: _, def: Symbol(name)}):
                                if (name == "body") {
                                    KissError.warnFromExp(arg, "Consider using &body instead of &rest when writing macros with bodies.");
                                }
                                argNames.push(name);
                                macroCallForm += ' <$name...>';
                                restIndex = maxArgs;
                                maxArgs = null;
                            case MetaExp("body", {pos: _, def: Symbol(name)}):
                                argNames.push(name);
                                macroCallForm += ' <$name...>';
                                restIndex = maxArgs;
                                requireRest = true;
                                maxArgs = null;
                            default:
                                throw KissError.fromExp(arg, "macro argument should be an untyped symbol or a symbol annotated with &opt, &rest, &body or &builder");
                        }
                }
            }

            macroCallForm += ')';
            if (optIndex == -1)
                optIndex = minArgs;
            if (restIndex == -1)
                restIndex = optIndex;

            k.doc(name, minArgs, maxArgs, macroCallForm);
            macros[name] = (wholeExp:ReaderExp, innerExps:Array<ReaderExp>, k:KissState) -> {
                var b = wholeExp.expBuilder();
                var innerArgNames = argNames.copy();

                var args:Map<String, Dynamic> = [];
                if (builderName != null) {
                    args[builderName] = b;
                }
                for (idx in 0...optIndex) {
                    args[innerArgNames.shift()] = innerExps[idx];
                }
                for (idx in optIndex...restIndex) {
                    args[innerArgNames.shift()] = if (exps.length > idx) innerExps[idx] else null;
                }
                if (innerArgNames.length > 0) {
                    var restArgs = innerExps.slice(restIndex);
                    if (requireRest && restArgs.length == 0) {
                        throw KissError.fromExp(wholeExp, 'Macro $name requires one or more expression for &body');
                    }
                    args[innerArgNames.shift()] = restArgs;
                }

                try {
                    // Return the macro expansion:
                    return Helpers.runAtCompileTime(b.callSymbol("begin", exps.slice(2)), k, args);
                } catch (error:KissError) {
                    throw error;
                } catch (error:Dynamic) {
                    // TODO this could print the hscript, with some refactoring
                    throw KissError.fromExp(wholeExp, 'Macro expansion error: $error');
                };
            };

            null;
        };
        renameAndDeprecate("defmacro", "defMacro");

        k.doc("undefmacro", 1, 1, '(undefMacro <name>)');
        macros["undefmacro"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            k.stateChanged = true;
            var name = switch (exps[0].def) {
                case Symbol(name): name;
                default: throw KissError.fromExp(exps[0], "macro name should be a symbol");
            };

            k.macros.remove(name);
            null;
        };
        renameAndDeprecate("undefmacro", "undefMacro");

        k.doc("defreadermacro", 3, null, '(defReaderMacro <optional &start> <"<startingString>" or [<startingStrings...>]> [<streamArgName>] <body...>)');
        macros["defreadermacro"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            k.stateChanged = true;

            // reader macros declared in the form (defreadermacro &start ...) will only be applied
            // at the beginning of lines
            var table = k.readTable;

            // reader macros can define a list of strings that will trigger the macro. When there are multiple,
            // the macro will put back the initiating string into the stream so you can check which one it was
            var strings = switch (exps[0].def) {
                case MetaExp("start", stringsExp):
                    table = k.startOfLineReadTable;
                    stringsThatMatch(stringsExp, "defReaderMacro");
                case MetaExp("bof", stringsExp):
                    table = k.startOfFileReadTable;
                    stringsThatMatch(stringsExp, "defReaderMacro");
                case MetaExp("eof", stringsExp):
                    table = k.endOfFileReadTable;
                    stringsThatMatch(stringsExp, "defReaderMacro");
                default:
                    stringsThatMatch(exps[0], "defReaderMacro");
            };

            var streamArgName = null;
            var builderArgName = null;
            var messageForBadArgs = KissError.fromExp(exps[1], 'expected an argument list for a reader macro, like [stream] or [stream &builder b]');
            switch (exps[1].def) {
                case ListExp(args):
                    for (arg in args) {
                        switch (arg.def) {
                            case Symbol(s):
                                streamArgName = s;
                            case MetaExp("builder", { pos: _, def: Symbol(b) }):
                                if (builderArgName == null) {
                                    builderArgName = b;
                                } else {
                                    throw KissError.fromExp(arg, 'Cannot declare multiple &builder args. Already declared: $builderArgName');
                                }
                            default:
                                throw messageForBadArgs;
                        }
                    }
                default:
                    throw messageForBadArgs;
            }
            if (streamArgName == null) throw messageForBadArgs;

            for (s in strings) {
                table[s] = (stream, k) -> {
                    if (strings.length > 1) {
                        stream.putBackString(s);
                    }
                    var startingPos = stream.position();
                    var body = CallExp(Symbol("begin").withPos(startingPos), exps.slice(2)).withPos(startingPos);
                    var evalArgs:Map<String,Dynamic> = [streamArgName => stream];
                    if (builderArgName != null) evalArgs[builderArgName] = body.expBuilder();
                    try {
                        Helpers.runAtCompileTime(body, k, evalArgs).def;
                    } catch (err) {
                        var expForError = Symbol(s).withPos(startingPos);
                        KissError.warnFromExp(wholeExp, 'Error from this reader macro');
                        throw KissError.fromExp(expForError, '$err');
                    }
                };
            }

            return null;
        };
        renameAndDeprecate("defreadermacro", "defReaderMacro");

        k.doc("undefreadermacro", 1, 1, '(undefReaderMacro <optional &start> ["<startingString>" or <startingStrings...>])');
        macros["undefreadermacro"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            k.stateChanged = true;
            // reader macros undeclared in the form (undefReaderMacro &start ...) will be removed from the table
            // for reader macros that must be at the beginning of lines
            // at the beginning of lines
            var table = k.readTable;

            // reader macros can define a list of strings that will trigger the macro. When there are multiple,
            // this macro will undefine all of them
            var strings = switch (exps[0].def) {
                case MetaExp("start", stringsExp):
                    table = k.startOfLineReadTable;
                    stringsThatMatch(stringsExp, "undefReaderMacro");
                case MetaExp("bof", stringsExp):
                    table = k.startOfFileReadTable;
                    stringsThatMatch(stringsExp, "undefReaderMacro");
                case MetaExp("eof", stringsExp):
                    table = k.endOfFileReadTable;
                    stringsThatMatch(stringsExp, "undefReaderMacro");
                default:
                    stringsThatMatch(exps[0], "undefReaderMacro");
            };
            for (s in strings) {
                table.remove(s);
            }
            return null;
        };
        renameAndDeprecate("undefreadermacro", "undefReaderMacro");

        // Having this floating out here is sketchy, but should work out fine because the variable is always re-set
        // through the next function before being used in defalias or undefalias
        var aliasMap:Map<String, ReaderExpDef> = null;

        function getAliasName(k:KissState, nameExpWithMeta:ReaderExp, formName:String):String {
            var error = KissError.fromExp(nameExpWithMeta, 'first argument to $formName should be &call [alias] or &ident [alias]');
            var nameExp = switch (nameExpWithMeta.def) {
                case MetaExp("call", nameExp):
                    aliasMap = k.callAliases;
                    nameExp;
                case MetaExp("ident", nameExp):
                    aliasMap = k.identAliases;
                    nameExp;
                default:
                    throw error;
            };
            return switch (nameExp.def) {
                case Symbol(whenItsThis):
                    whenItsThis;
                default:
                    throw error;
            };
        }

        k.doc("defalias", 2, 2, "(defAlias <<&call or &ident> whenItsThis> <makeItThis>)");
        macros["defalias"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            k.stateChanged = true;
            var name = getAliasName(k, exps[0], "defAlias");

            aliasMap[name] = exps[1].def;
            return null;
        };
        renameAndDeprecate("defalias", "defAlias");

        k.doc("undefalias", 1, 1, "(undefAlias <<&call or &ident> alias>)");
        macros["undefalias"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            k.stateChanged = true;
            var name = getAliasName(k, exps[0], "undefAlias");

            aliasMap.remove(name);
            return null;
        };
        renameAndDeprecate("undefalias", "undefAlias");

        // Macros that null-check and extract patterns from enums (inspired by Rust)
        function ifLet(assertLet:Bool, wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) {
            var funcName = if (assertLet) "assertLet" else "ifLet";
            var thenExpStr = if (assertLet) "<body...>" else "<thenExp>";
            var elseExpStr = if (assertLet) "" else " <?elseExp>";
            var maxArgs = if (assertLet) null else 3;
            k.doc(funcName, 2, maxArgs, '($funcName [<enum bindings...>] ${thenExpStr}${elseExpStr})');
            var b = wholeExp.expBuilder();

            var bindingList = exps[0].bindingList(funcName);
            var firstPattern = bindingList.shift();
            var firstValue = bindingList.shift();

            var thenExp = if (assertLet) b.begin(exps.slice(1)) else exps[1];
            var elseExp = if (!assertLet && exps.length > 2) {
                exps[2];
            } else if (assertLet) {
                b.callSymbol("throw", [b.str('Assertion binding ${firstValue.def.toString()} -> ${firstPattern.def.toString()} failed')]);
            } else {
                b.symbol("null");
            };

            var gensym = b.symbol();
            return b.let(
                [gensym, firstValue],
                [b.callSymbol("if", [
                    gensym,
                    b.callSymbol("case", [
                        gensym,
                        b.call(firstPattern, [
                                if (bindingList.length == 0) {
                                    thenExp;
                                } else {
                                    ifLet(assertLet, wholeExp, [
                                        b.list(bindingList)
                                    ].concat(exps.slice(1)), k);
                                }
                            ]),
                        b.callSymbol("otherwise", [
                            elseExp
                        ])
                    ]),
                    elseExp
                ])]);
        }
        macros["ifLet"] = ifLet.bind(false);

        k.doc('whenLet', 2, null, "(whenLet [<enum bindings...>] <body...>)");
        macros["whenLet"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            b.callSymbol("ifLet", [
                exps[0],
                b.begin(exps.slice(1)),
                b.symbol("null")
            ]);
        };

        k.doc("unlessLet", 2, null, "(unlessLet [<enum bindings...>] <body...>)");
        macros["unlessLet"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            b.callSymbol("ifLet", [
                exps[0],
                b.symbol("null"),
                b.begin(exps.slice(1))
            ]);
        };

        macros["assertLet"] = ifLet.bind(true);

        k.doc("awaitLet", 2, null, "(awaitLet [<promise bindings...>] <?catchHandler> <body...>)");
        function awaitLet(rejectionHandler:ReaderExp, wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) {
            var bindingList = exps[0].bindingList("awaitLet");

            var firstName = bindingList.shift();
            var firstValue = bindingList.shift();
            var b = wholeExp.expBuilder();

            var rejectionHandlerArgsAndBody = [];
            if (rejectionHandler == null) {
                function error(firstName:ReaderExp) {
                    return b.callSymbol("+", [b.str('awaitLet ${firstName.symbolNameValue()} rejected promise: '), b.symbol("reason")]);
                }
                rejectionHandler = b.symbol();    
                rejectionHandlerArgsAndBody = switch (exps[1].def) {
                    case CallExp({pos: _, def: Symbol("catch")}, catchArgs):
                        exps.splice(1,1);
                        catchArgs;
                    default:
                        [b.list([b.symbol("reason")])].concat([
                            b.callSymbol("#when", [
                                b.symbol("vscode"),
                                b.callSymbol("Vscode.window.showErrorMessage", [error(firstName)]),
                            ]),
                            // If running VSCode js, this throw will be a no-op but it makes the expression type-unify:
                            b.callSymbol("throw", [
                                error(firstName)
                            ])
                        ]);
                }
            }

            var innerExp = if (bindingList.length == 0) {
                b.begin(exps.slice(1));
            } else {
                awaitLet(rejectionHandler, wholeExp, [b.list(bindingList)].concat(exps.slice(1)), k);
            };
            switch(firstName.def) {
                case MetaExp("sync", firstName):
                    return b.let([firstName, firstValue], [innerExp]);
                case MetaExp(other, _):
                    throw KissError.fromExp(firstName, 'bad meta annotation &$other');
                default:
            }

            var exp = b.call(b.field("then", firstValue), [
                b.callSymbol("lambda", [
                    b.list([firstName]),
                    innerExp
                ]),
                rejectionHandler
            ]);
            
            if (rejectionHandlerArgsAndBody.length > 0) {
                exp = b.callSymbol("withFunctions", [
                    b.list([b.call(b.typed("Dynamic", rejectionHandler),
                                rejectionHandlerArgsAndBody)]),
                    exp
                ]);
            }

            return exp;
        }
       
        macros["awaitLet"] = awaitLet.bind(null);
        
        k.doc("whileLet", 2, null, "(whileLet [<bindings...>] <body...>)");
        macros["whileLet"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            return b.callSymbol("loop", [
                b.callSymbol("ifLet", [
                    exps[0],
                        b.begin(exps.slice(1)),
                    b.callSymbol("break", [])
                ])
            ]);
        };

        k.doc("defnew", 1, null, "(defNew [<args...>] [<optional property bindings...>] <optional body...>");
        macros["defnew"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var args = exps.shift();
            var bindingList = [];

            if (exps.length != 0) {
                switch (exps[0].def) {
                    case ListExp(_):
                        bindingList = exps.shift().bindingList("defNew", true);
                    default:
                }
            }
            var bindingPairs = Prelude.groups(bindingList, 2);

            var propertyDefs = [for (bindingPair in bindingPairs) {
                var b = bindingPair[0].expBuilder();
                b.call(b.symbol("prop"), [bindingPair[0]]);
            }];
            var propertySetExps = [for (bindingPair in bindingPairs) {
                var b = bindingPair[1].expBuilder();
                b.call(b.symbol("set"), [b.symbol(Helpers.varName("a prop property binding", bindingPair[0])), bindingPair[1]]);
            }];

            var firstExps = [];
            // &first (super <...>) ensures super is called before anything else (for extending native classes).
            // You can put more than one expression &first but they all have to come before non-first expressions (for readability)
            while (exps.length > 0) {
                switch (exps[0].def) {
                    case MetaExp("first", exp):
                        exps.shift();
                        firstExps.push(exp);
                    default:
                        break;
                }
            }

            var argList = [];
            // &prop in the argument list defines a property supplied directly as an argument
            for (arg in Helpers.argList(args, "defNew")) {
                var b = arg.expBuilder();
                switch (arg.def) {
                    case MetaExp("prop", propExp):
                        // TODO allow the reverse order (&mut &prop)
                        var propDeclExp = propExp;
                        switch (propExp.def) {
                            case MetaExp("mut", innerExp):
                                propExp = innerExp;
                            default:
                        }
                        argList.push(propExp);
                        propertyDefs.push(
                            b.call(b.symbol("prop"), [propDeclExp]));
                        switch (propExp.def) {
                            case TypedExp(_, {pos: _, def: Symbol(name)}):
                                propertySetExps.push(
                                    b.call(b.symbol("set"), [b.field(name, b.symbol("this")), b.symbol(name)]));
                            case Symbol(name):
                                throw KissError.fromExp(arg, '&prop constructor argument $name must be typed');
                            default:
                                throw KissError.fromExp(arg, "invalid use of &prop in defNew");
                        }
                    default:
                        argList.push(arg);
                }
            }

            var b = wholeExp.expBuilder();

            return b.begin(propertyDefs.concat([
                b.call(b.symbol("method"), [
                    b.symbol("new"),
                    b.list(argList)
                ].concat(firstExps).concat(propertySetExps).concat(exps))
            ]));
        };
        renameAndDeprecate("defnew", "defNew");

        k.doc("collect", 1, 1, "(collect <iterator or iterable>)");
        macros["collect"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            b.call(b.symbol("for"), [b.symbol("elem"), exps[0], b.symbol("elem")]);
        };

        function once(macroName:String, wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) {
            k.doc(macroName, 1, null, '($macroName <body...>)');
            var b = wholeExp.expBuilder();
            var flag = b.symbol();
            // define the field:
            k.convert(b.call(b.symbol(macroName), [b.meta("mut", flag), b.symbol("true")]));
            return b.call(b.symbol("when"), [flag, b.call(b.symbol("set"), [flag, b.symbol("false")])].concat(exps));
        }

        macros["once"] = once.bind("var");
        macros["oncePerInstance"] = once.bind("prop");

        k.doc("defMacroVar", 2, 2, "(defMacroVar <name> <value>)");
        macros["defMacroVar"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            k.stateChanged = true;
            var name = exps[0].symbolNameValue();

            k.macroVars[name] = Helpers.runAtCompileTimeDynamic(exps[1], k);

            return null;
        };

        k.doc("setMacroVar",2, 2, "(setMacroVar <name> <value>)");
        macros["setMacroVar"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            k.stateChanged = true;
            var name = exps[0].symbolName().withPosOf(exps[0]);
            var b = wholeExp.expBuilder();
            
            return b.callSymbol("_setMacroVar", [name, exps[1]]);
        };

        k.doc("defMacroFunction", 3, null, "(defMacroFunction <name> [<args>] <body...>)");
        macros["defMacroFunction"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            k.stateChanged = true;
            var b = wholeExp.expBuilder();
            var name = exps[0].symbolNameValue();
            var lambdaExp = b.callSymbol("lambda", [exps[1]].concat(exps.slice(2)));

            k.macroVars[name] = Helpers.runAtCompileTimeDynamic(lambdaExp, k);
            // Run the definition AGAIN so it can capture itself recursively:
            k.macroVars[name] = Helpers.runAtCompileTimeDynamic(lambdaExp, k);

            return null;
        };

        // Replace "try" with this in a try-catch statement to let all exceptions throw
        // their original call stacks. This is more convenient for debugging than trying to
        // comment out the "try" and its catches, and re-balance parens
        k.doc("letThrow", 1, null, "(letThrow <thing> <catches...>)");
        macros["letThrow"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            exps[0];
        };

        k.doc("objectWith", 1, null, "(objectWith <?[<bindings...>]> <fieldNames...>)");
        macros["objectWith"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var objectExps = try {
                var l = Helpers.bindingList(exps[0], "field bindings for objectWith", true);
                exps.shift();
                l;
            } catch (_notABindingList) {
                [];
            }

            for (exp in exps) {
                switch (exp.def) {
                    case Symbol(_):
                        objectExps.push(exp);
                        objectExps.push(exp);
                    default:
                        throw KissError.fromExp(exp, "invalid expression in (objectWith)");
                }
            }

            var b = wholeExp.expBuilder();
            b.callSymbol("object", objectExps);
        }

        // Macro for triggering collection of expressions throughout a Kiss file, to inject them later with collectedBlocks
        k.doc("collectBlocks", 1, 2, "(collectBlocks <block symbol> <?expression to inline instead of the blocks>)");
        macros["collectBlocks"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var blockName = try {
                exps[0].symbolNameValue();
            } catch (notSymbolError:String) {
                throw KissError.fromExp(wholeExp, notSymbolError);
            }
            k.collectedBlocks[blockName] = [];
            // TODO some assertion that the coder hasn't defined over another macro (also should apply to defMacro)
            macros[blockName] = (wholeExp:ReaderExp, innerExps:Array<ReaderExp>, k:KissState) -> {
                k.collectedBlocks[blockName] = k.collectedBlocks[blockName].concat(innerExps);
                if (exps.length > 1) exps[1] else null;
            };
            null;
        };

        k.doc("collectedBlocks", 1, 1, "(collectedBlocks <block symbol>)");
        macros["collectedBlocks"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var blockName = try {
                exps[0].symbolNameValue();
            } catch (notSymbolError:String) {
                throw KissError.fromExp(wholeExp, notSymbolError);
            }
            var b = wholeExp.expBuilder();
            if (!k.collectedBlocks.exists(blockName)) {
                throw KissError.fromExp(wholeExp, 'no blocks for $blockName were collected. Try adding (collectBlocks ${blockName}) at the start of the file.');
            }
            b.begin(k.collectedBlocks[blockName]);
        };

        // These are implemented as variadic functions, so checkNumArgs() is never actually called,
        // but the docs might be useful
        k.doc("min", 2, null, "(min <v1> <v2> <more values...>)");
        k.doc("max", 2, null, "(max <v1> <v2> <more values...>)");

        k.doc("setMin", 2, null, "(setMin <var> <v2> <more values...>)");
        k.doc("setMax", 2, null, "(setMax <var> <v2> <more values...>)");
        function setCompMacro(compType:String) {
            return (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
                var b = wholeExp.expBuilder();
                b.set(exps[0], b.callSymbol(compType, exps));
            }
        }
        macros["setMin"] = setCompMacro("min");
        macros["setMax"] = setCompMacro("max");

        k.doc("clamp", 2, 3, "(clamp <expr> <min or null> <?max or null>)");
        macros["clamp"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            var maxExp = if (exps.length == 3) exps.pop() else b.symbol("null");
            var expToSet = exps.shift();
            var minExp = exps.shift();
            var min = b.symbol("minVal");
            var max = b.symbol("maxVal");
            b.callSymbol("let", [
                b.list([
                    min, minExp,
                    max, maxExp
                ]),
                b.callSymbol("when", [
                    min,
                    b.callSymbol("set", [expToSet, b.callSymbol("max", [min, expToSet])])
                ]),
                b.callSymbol("when", [
                    max,
                    b.callSymbol("set", [expToSet, b.callSymbol("min", [max, expToSet])])
                ]),
                expToSet
            ]);
        };

        // The wildest code in Kiss to date
        // TODO test exprCase!!
        k.doc("exprCase", 2, null, "(exprCase <expr> <pattern callExps...>)");
        macros["exprCase"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var toMatch = exps.shift();
            var b = wholeExp.expBuilder();
            var functionKey = Uuid.v4();

            exprCaseFunctions[functionKey] = (toMatchValue:ReaderExp) -> {
                for (patternExp in exps) {
                    switch (patternExp.def) {
                        case CallExp(pattern, body):
                            if (matchExpr(pattern, toMatchValue)) {
                                return b.begin(body);
                            }
                        default:
                            throw KissError.fromExp(patternExp, "bad exprCase pattern expression");
                    }
                }

                throw KissError.fromExp(wholeExp, 'expression ${toMatchValue.def.toString()} matches no pattern in exprCase');
            };

            return b.call(b.symbol("Macros.exprCase"), [b.str(functionKey), toMatch, b.symbol("__interp__")]);
        };

        // Maybe the NEW wildest code in Kiss?
        k.doc("#extern", 4, null, "(#extern <BodyType> <lang> <?compileArgs object> [<typed bindings...>] <body...>)");
        macros["#extern"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();

            // Skip all extern code generation if -D no-extern is provided to the compiler
            if (Context.defined("no-extern")) {
                return b.callSymbol("throw", [b.str("tried to call #extern code when -D no-extern was provided during compilation")]);
            }

            var bodyType = exps.shift();
            var langExp = exps.shift();
            var originalLang = langExp.symbolNameValue();
            // make the lang argument forgiving, because many will assume it can match the compiler defines and command-line arguments of Haxe
            var lang = switch (originalLang) {
                case "python" | "py": "Python";
                case "js" | "javascript": "JavaScript";
                default: originalLang;
            };

            var allowedLangs = EnumTools.getConstructors(CompileLang);
            if (allowedLangs.indexOf(lang) == -1) {
                throw KissError.fromExp(langExp, 'unsupported lang for #extern: $originalLang should be one of $allowedLangs');
            }
            var langArg = EnumTools.createByName(CompileLang, lang);

            var compileArgsExp = null;
            var bindingListExp = null;
            var nextArg = exps.shift();
            switch (nextArg.def) {
                case CallExp({pos: _, def: Symbol("object")}, _):
                    compileArgsExp = nextArg;
                    nextArg = exps.shift();
                case ListExp(_):
                // Let the next switch handle the binding list
                default:
                    throw KissError.fromExp(nextArg, "second argument to #extern can either be a CompileArgs object or a list of typed bindings");
            }
            switch (nextArg.def) {
                case ListExp(_):
                    bindingListExp = nextArg;
                default:
                    throw KissError.fromExp(nextArg, "#extern requires a list of typed bindings");
            }

            var compileArgs:CompilationArgs = if (compileArgsExp != null) {
                Helpers.runAtCompileTimeDynamic(compileArgsExp, k);
            } else {
                {};
            }

            var bindingList = bindingListExp.bindingList("#extern", true);

            var idx = 0;
            var stringifyExpList = [];
            var parseBindingList = [];
            while (idx < bindingList.length) {
                var type = "";
                var untypedName = switch (bindingList[idx].def) {
                    case TypedExp(_type, symbol = {pos: _, def: Symbol(name)}):
                        type = _type;
                        symbol;
                    default: throw KissError.fromExp(bindingList[idx], "name in #extern binding list must be a typed symbol");
                };
                switch (bindingList[idx + 1].def) {
                    // _ in the value position of the #extern binding list will reuse the name as the value
                    case Symbol("_"):
                        bindingList[idx + 1] = untypedName;
                    default:
                }

                stringifyExpList.push(b.the(b.symbol("String"), b.callSymbol("tink.Json.stringify", [b.the(b.symbol(type), bindingList[idx + 1])])));
                parseBindingList.push(bindingList[idx]);
                // This will be called in the context where __args__ is Sys.args()
                parseBindingList.push(b.callSymbol("tink.Json.parse", [b.callField("shift", b.symbol("__args__"), [])]));
                idx += 2;
            }

            var externExps = [
                b.let([b.symbol("__args__"), b.callSymbol("Sys.args", [])], [
                    b.callSymbol("set", [
                        b.symbol("Prelude.printStr"),
                        b.symbol("Prelude._externPrintStr")
                    ]),
                    b.callSymbol("Prelude._printStr", [
                        b.callSymbol("tink.Json.stringify", [
                            b.the(bodyType, if (bindingList.length > 0) {
                                b.let(parseBindingList, exps);
                            } else {
                                b.begin(exps);
                            })
                        ])
                    ]),
                    b.callSymbol("Sys.exit", [b.symbol("0")])
                ])
            ];
            b.the(
                bodyType,
                b.callSymbol("tink.Json.parse", [
                    b.call(b.raw(CompilerTools.compileToScript(externExps, langArg, compileArgs, wholeExp).toString()), [b.list(stringifyExpList)])
                ]));
        };

        k.doc("countingLambda", 3, null, "(countingLambda <countVar> [<argsNames...>] <body...>)");
        macros["countingLambda"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();

            var countVarSymbol = exps[0];
            var args = exps[1];
            var body = exps.slice(2);

            return b.let([
                b.meta("mut", countVarSymbol), b.int(0)
            ], [b.callSymbol("lambda", [
                args,
                b.callSymbol("+=", [
                    countVarSymbol,
                    b.int(1)
                ])
            ].concat(body))]);
        };

        // Time a block's evaluation
        k.doc("measureTime",1, null, "(measureTime <body...>)");
        macros["measureTime"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();

            return b.callSymbol("haxe.Timer.measure", [b.callSymbol("lambda", [b.list([])].concat(exps))]);
        };

        // TODO should indexOf and lastIndexOf accept negative starting indices?
        function indexOfMacro(last:Bool, wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) {
            var funcName = if (last) "lastIndexOf" else "indexOf";
            k.doc(funcName, 2, 3, '($funcName <list or string> <element or substring> <?startingIndex>)');
            var b = wholeExp.expBuilder();
            var cases = [
                b.callField(funcName, exps.shift(), exps),
                b.callSymbol("-1", [b.symbol("haxe.ds.Option.None")]),
                b.callSymbol("other", [b.callSymbol("haxe.ds.Option.Some", [b.symbol("other")])]),
                b.callSymbol("null", [b.callSymbol("throw", [b.str("Haxe indexOf is broken")])])
            ];
            return b.callSymbol("case", cases);
        }
        macros["indexOf"] = indexOfMacro.bind(false);
        macros["lastIndexOf"] = indexOfMacro.bind(true);

        // contains is a macro so it can be called on either an Array or a String
        k.doc("contains", 2, 2, '(contains <string or list> <snippet or element>)');
        macros["contains"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            return b.not(b.callSymbol("=", [b.symbol("-1"), b.callField("indexOf", exps[0], [exps[1]])]));
        }

        // Under the hood, quoted expressions are just Kiss strings for a KissInterp
        k.doc("quote", 1, 1, '(quote <exp>)');
        macros["quote"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            return b.str(Reader.toString(exps[0].def));
        };

        // Under the hood, (eval) uses Type.getClassFields, Type.getInstanceFields, and Reflect.field, to mishmash
        // a bunch of fields ONLY from (var) and (prop) in the class that called Kiss.build(), AT RUNTIME, into a KissInterp that evaluates a string of Kiss code.
        // This is all complicated, and language- and platform-dependent. And slow, because it converts Kiss to HScript at runtime.
        // When (eval) is used in a static function, it cannot access instance variables.
        // (eval) should not be used for serious purposes.
        k.doc("eval", 1, 1, '(eval <exp>)');
        macros["eval"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            var className = Context.getLocalClass().toString();
            var classSymbol = b.symbol(className);

            // TODO this might be reusable for passing things to #extern
            
            var classFieldsSymbol = b.symbol();
            var instanceFieldsSymbol = b.symbol();
            var interpSymbol = b.symbol();
            var bindings = [
                interpSymbol, b.callSymbol("new", [b.symbol("kiss.KissInterp")]),
                classFieldsSymbol, b.callSymbol("Type.getClassFields", [classSymbol]),
            ];
            if (!k.inStaticFunction) {
                bindings = bindings.concat([instanceFieldsSymbol, b.callSymbol("Type.getInstanceFields", [classSymbol])]);
            }
            var body = [
                b.callSymbol("doFor", [
                    b.symbol("staticField"), classFieldsSymbol,
                    b.callField("set", b.field("variables", interpSymbol), [
                        b.symbol("staticField"), b.callSymbol("Reflect.field", [classSymbol, b.symbol("staticField")])
                    ])
                ])
            ];
            if (!k.inStaticFunction) {
                body.push(
                    b.callSymbol("doFor", [
                        b.symbol("instanceField"), instanceFieldsSymbol,
                        b.callField("set", b.field("variables", interpSymbol), [
                            b.symbol("instanceField"), b.callSymbol("Reflect.field", [b.symbol("this"), b.symbol("instanceField")])
                        ])
                    ])
                );
            }
            body.push(b.callField("evalKiss", interpSymbol, [exps[0]]));
            b.let(bindings, body);
        };

        function typedCallMacro(name:String, symbol:String, type:String) {
            macros[name] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
                k.doc(name, 2, null, '($name <lists...>)');
                var b = wholeExp.expBuilder();
                b.callSymbol("the", [b.symbol(type), b.callSymbol('Prelude.$symbol', exps)]);
            };
        }
        typedCallMacro("zip", "zipThrow", "Array<Array<Dynamic>>");
        typedCallMacro("zipKeep", "zipKeep", "Array<Array<Dynamic>>");
        typedCallMacro("zipDrop", "zipDrop", "Array<Array<Dynamic>>");
        typedCallMacro("zipThrow", "zipThrow", "Array<Array<Dynamic>>");
        typedCallMacro("intersect", "intersect", "Array<Array<Dynamic>>");
        typedCallMacro("concat", "concat", "Array<Dynamic>");

        k.doc("withEvalOnce", 2, null, "(withEvalOnce [<symbols...>] <body...>)");
        macros["withEvalOnce"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            var symbols = exps[0].argList("withEvalOnce");
            var body = exps.slice(1);
            var bindings = [];
            for (symbol in symbols) {
                bindings.push(symbol);
                bindings.push(Unquote(symbol).withPosOf(symbol));
            }
            return Quasiquote(b.let(bindings, body)).withPosOf(wholeExp);
        };

        function printAll (locals:Bool, nullCheck:Bool, wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) {
            k.printFieldsCalls.push(wholeExp);
            var b = wholeExp.expBuilder();
            var list = if (locals) k.localVarsInScope else k.varsInScope;
            if (!locals && k.inStaticFunction) {
                list = [for (idx in 0...list.length) if (!k.varsInScopeAreStatic[idx]) continue; else list[idx]];
            }
            return b.begin([for (v in list) {
                var symbol = b.symbol(v.name);
                var pr = b.callSymbol("print", [symbol, b.str(v.name)]);
                if (nullCheck) {
                    pr = b.callSymbol("unless", [symbol, pr]);
                }
                pr;
            }]);
        }
        k.doc("printAll", 0, 0, "(printAll)");
        macros["printAll"] = printAll.bind(false, false);
        k.doc("printLocals", 0, 0, "(printLocals)");
        macros["printLocals"] = printAll.bind(true, false);
        k.doc("printAllNulls", 0, 0, "(printAllNulls)");
        macros["printAllNulls"] = printAll.bind(false, true);
        k.doc("printLocalNulls", 0, 0, "(printLocalNulls)");
        macros["printLocalNulls"] = printAll.bind(true, true);
        
        var savedVarFilename = null;
        k.doc("savedVarFile", 1, 1, '(savedVarFilename "<path>")');
        macros["savedVarFile"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            savedVarFilename = compileTimeResolveToString("The only argument to (savedVarFile...)", "a json filename", exps[0], k);
            null;
        };
        
        k.doc("savedVar", 2, 2, "(savedVar <:Type> <name> <initial value>)");
        macros["savedVar"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();
            var name = exps[0];
            var nameString = Prelude.symbolNameValue(name, true, false);
            var type = Helpers.explicitTypeString(name);
            var initialValue = exps[1];
            var filename = if (savedVarFilename != null) {
                if (!savedVarFilename.endsWith(".json"))
                    savedVarFilename = '${savedVarFilename}.json';
                b.str(savedVarFilename);
            } else {
                b.str("." + k.className + ".json");
            };
        
            function ifLetFileJson(thenBlock:Array<ReaderExp>, elseBlock:Array<ReaderExp>) {
                return b.callSymbol("if", [
                    b.callSymbol("and", [
                        b.callSymbol("sys.FileSystem.exists", [filename]),
                        b.not(b.callSymbol("sys.FileSystem.isDirectory", [filename]))
                    ]),
                    // then
                    b.let([
                        b.symbol("content"), b.callSymbol("sys.io.File.getContent", [filename]),
                        b.typed("haxe.DynamicAccess<String>", b.symbol("json")), b.callSymbol("haxe.Json.parse", [b.symbol("content")])
                    ], thenBlock),
                    // else
                    b.begin(elseBlock)
                ]);
            }
        
            var setAndSave = [
                b.callSymbol("dictSet", [b.symbol("json"), b.str(nameString), b.raw("tink.Json.stringify(v)")]),
                b.callSymbol("sys.io.File.saveContent", [filename, b.raw("haxe.Json.stringify(json)")]),
                b.raw("v;")
            ];
        
            b.begin([
                b.callSymbol("var", [name, b.callSymbol("property", [b.symbol("get"), b.symbol("set")])]),
                b.callSymbol(
                    "function", [
                        b.typed(type, b.symbol('get_${nameString}')), 
                        b.list([]), 
                        ifLetFileJson([
                            b.callSymbol("if", [
                                b.callSymbol("json.exists", [b.str(nameString)]),
                                b.raw("{ var v:" + type + " = tink.Json.parse(json['" + nameString + "']); v;}"),
                                initialValue
                            ])
                        ], 
                        [
                            initialValue
                        ])
                    ]),
                b.callSymbol(
                    "function", [
                        b.typed(type, b.symbol('set_${nameString}')), 
                        b.list([b.typed(type, b.symbol("v"))]), 
                        ifLetFileJson(
                            setAndSave,
                            [
                                b.let([b.typed("haxe.DynamicAccess<String>", b.symbol("json")), b.raw("haxe.Json.parse('{}')")], setAndSave)
                            ])
                    ])
            ]);
        };

        k.doc("withMutProperties", 2, null, "(withMutProperties [<vars...>] <body...>)");
        // Because properties like the ones created with savedVar won't automatically invoke their set() behavior when setNth, dictSet, or methods modify their object's data,
        // this macro exists to help you enforce that the set() behavior will be invoked. Also enforces that get() is only called once and the returned reference persists changes.
        macros["withMutProperties"] = (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();

            // TODO the nomenclature in the implementation is misleading. This macro is not just useful for savedVar properties.
            var savedVarList = Helpers.argList(exps[0], "withMutProperties");
            var uuids = [for (savedVar in savedVarList) {
                switch (savedVar.def) {
                    case Symbol(_):
                    default:
                        throw KissError.fromExp(savedVar, "withMutProperties requires its initial arguments to be plain symbols of property names");
                }
                b.symbol();
            }];

            var body = exps.slice(1);
            b.let(Lambda.flatten(Prelude.zipThrow(uuids, savedVarList)), [
                b.let(Lambda.flatten(Prelude.zipThrow(savedVarList, uuids)), body),
            ].concat([for (savedVar in savedVarList) b.set(savedVar, uuids.shift())]));
        };

        k.doc("withFunctions", 2, null, "(withFunctions [(<funcName1> [<args...>] <body...>) <more functions...>] <body...>)");
        macros["withFunctions"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();

            var funcList = Helpers.argList(args[0], "withFunctions");
            if (funcList.length == 0) throw KissError.fromExp(args[0], "withFunctions requires at least one function definition");
            var localFunctions = [];
            do {
                var funcExp = funcList.shift();
                switch (funcExp.def) {
                    case CallExp(nameExp, argsAndBody) if (argsAndBody.length >= 2):
                        localFunctions.push(b.callSymbol("localFunction", [
                            nameExp, argsAndBody.shift()
                        ].concat(argsAndBody)));
                    default:
                        throw KissError.fromExp(funcExp, "withFunctions function definition should follow this form: (<funcName> [<args...>] <body...>)");
                }
                
            } while (funcList.length > 0);

            var exp = b.begin(localFunctions.concat(args.slice(1)));
            // Prelude.print(Reader.toString(exp.def));
            exp;
        };
        
        k.doc("typeCase", 2, null, "(typeCase [<values>] ([:<Type> <name> <more typed names...>] <body>) <more cases...> (otherwise <required default>))");
        macros["typeCase"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var b = wholeExp.expBuilder();

            var argsListExp = args.shift();
            var argsList = Helpers.argList(argsListExp, "typeCase", false);

            var cases:kiss.List<ReaderExp> = [for (c in args) {
                c.expBuilder().neverCase();
            }];

            Helpers.checkNoEarlyOtherwise(cases);

            var symbols = [for (i in 0...argsList.length) b.symbol()];
            var dynamicSymbols = [for (s in symbols) b.typed("Dynamic", s)];
            var outerLetBindings = [];
            for (i in 0...argsList.length) {
                outerLetBindings.push(dynamicSymbols[i]);
                outerLetBindings.push(argsList[i]);
            }

            cases = [for (c in cases) {
                var b = c.expBuilder();
                switch (c.def) {
                    case CallExp({pos:_, def:ListExp(typedNames)}, body):
                        var names = [];
                        var types = [];
                        var typesWithoutGenerics = [];
                        for (exp in typedNames) {
                            switch (exp.def) {
                                case TypedExp(type, nameSymbol):
                                    names.push(nameSymbol);
                                    types.push(type);
                                    if (type.contains("<")) {
                                        type = type.substr(0, type.indexOf("<"));
                                    }
                                    typesWithoutGenerics.push(type);
                                default:
                                    throw KissError.fromExp(c, "bad typeCase case");
                            }
                        }
                        var letBindings = [];
                        for (i in 0...names.length) {
                            letBindings.push(typedNames[i]);
                            letBindings.push(names[i]);
                        }
                        b.call(b.callSymbol("when", [b.callSymbol("and", [
                            for (i in 0...names.length) {
                                b.callSymbol("Std.isOfType", [names[i], b.symbol(typesWithoutGenerics[i])]);
                            }
                        ]), b.list(names)]), [b.let(letBindings, body)]);
                    default: c;
                }
            }];
            
            b.let(outerLetBindings, [
                b.callSymbol("case", [b.list(symbols)].concat(cases))
            ]);
        }
        
        return macros;
    }

    static var exprCaseFunctions:Map<String, ReaderExp->ReaderExp> = [];

    public static function exprCase(id:String, toMatchValue:ReaderExp, i:KissInterp):ReaderExp {
        return i.variables["eval"](exprCaseFunctions[id](toMatchValue));
    }

    static function matchExpr(pattern:ReaderExp, instance:ReaderExp):Bool {
        switch (pattern.def) {
            case Symbol("_"):
                return true;
            case CallExp({pos: _, def: Symbol("exprOr")}, altPatterns):
                for (altPattern in altPatterns) {
                    if (matchExpr(altPattern, instance))
                        return true;
                }
                return false;
            case Symbol(patternSymbol):
                return switch (instance.def) {
                    case Symbol(instanceSymbol) if (patternSymbol == instanceSymbol):
                        true;
                    default:
                        false;
                };
            case CallExp({pos: _, def: Symbol("exprTyped")}, [type, patternExp]):
                var patternTypePath = Prelude.symbolNameValue(type);
                return switch (instance.def) {
                    case TypedExp(typePath, instanceExp) if (typePath == patternTypePath):
                        matchExpr(patternExp, instanceExp);  
                    default:
                        false;
                };
            case ListExp(patternExps):
                switch (instance.def) {
                    case ListExp(instanceExps) if (patternExps.length == instanceExps.length):
                        for (idx in 0...patternExps.length) {
                            if (!matchExpr(patternExps[idx], instanceExps[idx]))
                                return false;
                        }
                        return true;
                    default:
                        return false;
                }
            case CallExp(patternFuncExp, patternExps):
                switch (instance.def) {
                    case CallExp(instanceFuncExp, instanceExps) if (patternExps.length == instanceExps.length):
                        if (!matchExpr(patternFuncExp, instanceFuncExp))
                            return false;
                        for (idx in 0...patternExps.length) {
                            if (!matchExpr(patternExps[idx], instanceExps[idx]))
                                return false;
                        }
                        return true;
                    default:
                        return false;
                }
            case MetaExp(metaStr, patternExp):
                return switch (instance.def) {
                    case MetaExp(instanceMetaStr, instanceExp) if (instanceMetaStr == metaStr):
                        matchExpr(patternExp, instanceExp);
                    default:
                        false;
                };
            // I don't think I'll ever want to match specific string literals, raw haxe, field expressions,
            // key-value expressions, quasiquotes, unquotes, or UnquoteLists. This function can be expanded
            // later if those features are ever needed.
            default:
                throw KissError.fromExp(pattern, "unsupported pattern for exprCase");
        }
    }

    // cond expands telescopically into a nested if expression
    static function addCond(k:KissState, macros:Map<String,MacroFunction>, formName:String, underlyingIf:String) {
        k.doc(formName, 1, null, '($formName (<condition> <body...>) <more cases...>)');
        function cond (wholeExp:ReaderExp, exps:Array<ReaderExp>, k:KissState) {
            var b = wholeExp.expBuilder();
            return switch (exps[0].def) {
                case CallExp(condition, body):
                    b.call(b.symbol(underlyingIf), [
                        condition,
                        b.begin(body),
                        if (exps.length > 1) {
                            cond(b.callSymbol(formName, exps.slice(1)), exps.slice(1), k);
                        } else {
                            b.symbol("null");
                        }
                    ]);
                default:
                    throw KissError.fromExp(exps[0], 'top-level expression of ($formName... ) must be a call list starting with a condition expression');
            };
        }
        macros[formName] = cond;
    }
}
