package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.PositionTools;
import hscript.Parser;
import hscript.Interp;
import kiss.Reader;
import kiss.ReaderExp;
import kiss.KissError;
import kiss.Kiss;
import kiss.SpecialForms;
import kiss.Prelude;
import kiss.cloner.Cloner;
import uuid.Uuid;
import sys.io.Process;

using uuid.Uuid;
using tink.MacroApi;
using kiss.Reader;
using kiss.Helpers;
using kiss.Kiss;
using StringTools;
using haxe.macro.ExprTools;

/**
 * Compile-time helper functions for Kiss. Don't import or reference these at runtime.
 */
class Helpers {
    public static function macroPos(exp:ReaderExp) {
        var kissPos = exp.pos;
        return PositionTools.make({
            min: kissPos.absoluteChar,
            max: kissPos.absoluteChar,
            file: kissPos.file
        });
    }

    public static function withMacroPosOf(e:ExprDef, exp:ReaderExp):Expr {
        return {
            pos: macroPos(exp),
            expr: e
        };
    }

    static function startsWithUpperCase(s:String) {
        return s.charAt(0) == s.charAt(0).toUpperCase();
    }

    public static function parseTypePath(path:String, ?from:ReaderExp):TypePath {
        return switch (parseComplexType(path, from)) {
            case TPath(path):
                path;
            default:
                var errorMessage = 'Haxe could not parse a type path from $path';
                if (from == null) {
                    throw errorMessage;
                } else {
                    throw KissError.fromExp(from, errorMessage);
                }
        };
    }

    public static function parseComplexType(path:String, ?from:ReaderExp):ComplexType {
        // Trick Haxe into parsing it for us:
        var typeCheckStr = '(thing : $path)';
        var errorMessage = 'Haxe could not parse a complex type from `$path` in `${typeCheckStr}`';
        
        function throwError() {
            if (from == null) {
                throw errorMessage;
            } else {
                throw KissError.fromExp(from, errorMessage);
            };
        }
        try {
            var typeCheckExpr = Context.parse(typeCheckStr, Context.currentPos());
            return switch (typeCheckExpr.expr) {
                case EParenthesis({pos: _, expr: ECheckType(_, complexType)}):
                    complexType;
                default:
                    throwError();
                    return null;
            };
        } catch (err) {
            throwError();
            return null;
        }
    }

    public static function explicitTypeString(nameExp:ReaderExp):String {
        return switch (nameExp.def) {
            case MetaExp(_, innerExp):
                explicitTypeString(innerExp);
            case TypedExp(type, _):
                type;
            default: null;
        };
    }

    public static function explicitType(nameExp:ReaderExp):ComplexType {
        var string = explicitTypeString(nameExp);
        if (string == null) return null; 
        return Helpers.parseComplexType(string, nameExp);
    }

    public static function varName(formName:String, nameExp:ReaderExp, nameType = "variable") {
        return switch (nameExp.def) {
            case Symbol(name):
                name;
            case MetaExp(_, nameExp) | TypedExp(_, nameExp):
                varName(formName, nameExp);
            default:
                throw KissError.fromExp(nameExp, 'The first argument to $formName should be a $nameType name, :Typed $nameType name, and/or &meta $nameType name.');
        };
    }

    public static function makeTypeParam(param:ReaderExp, ?constraints:Array<ComplexType> = null):TypeParamDecl {
        if (constraints == null) constraints = [];
        switch (param.def) {
            case Symbol(name):
                return {
                    name: name,
                    constraints: constraints
                };
            case TypedExp(type, param):
                constraints.push(parseComplexType(type));
                return makeTypeParam(param, constraints);
            default:
                throw KissError.fromExp(param, "expected <GenericTypeName> or :<Constraint> <GenericTypeName>");
        }
    }

    public static function makeFunction(?name:ReaderExp, returnsValue:Bool, argList:ReaderExp, body:List<ReaderExp>, k:KissState, formName:String, typeParams:Array<ReaderExp>):Function {
        var funcName = if (name != null) {
            varName(formName, name, "function");
        } else {
            "";
        };

        var params = [for (p in typeParams) makeTypeParam(p)];

        var numArgs = 0;
        // Once the &opt meta appears, all following arguments are optional until &rest
        var opt = false;
        // Once the &rest meta appears, no other arguments can be declared
        var rest = false;
        var restProcessed = false;

        function makeFuncArg(funcArg:ReaderExp):FunctionArg {
            if (restProcessed) {
                throw KissError.fromExp(funcArg, "cannot declare more arguments after a &rest argument");
            }
            return switch (funcArg.def) {
                case MetaExp("rest", innerFuncArg):
                    if (funcName == "") {
                        throw KissError.fromExp(funcArg, "lambda does not support &rest arguments");
                    }

                    // rest arguments define a Kiss special form with the function's name that wraps
                    // the rest args in a list when calling it from Kiss
                    k.specialForms[funcName] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
                        var realCallArgs = args.slice(0, numArgs);
                        var restArgs = args.slice(numArgs);
                        realCallArgs.push(ListExp(restArgs).withPosOf(wholeExp));
                        ECall(k.convert(Symbol(funcName).withPosOf(wholeExp)), realCallArgs.map(k.convert)).withMacroPosOf(wholeExp);
                    };

                    opt = true;
                    rest = true;
                    makeFuncArg(innerFuncArg);
                case MetaExp("opt", innerFuncArg):
                    opt = true;
                    makeFuncArg(innerFuncArg);
                default:
                    if (rest) {
                        restProcessed = true;
                    } else {
                        ++numArgs;
                    }
                    {
                        // These could use varName() and explicitType() but so far there are no &meta annotations for function arguments
                        name: switch (funcArg.def) {
                            case Symbol(name) | TypedExp(_, {pos: _, def: Symbol(name)}):
                                name;
                            default:
                                throw KissError.fromExp(funcArg, 'function argument should be a symbol or typed symbol');
                        },
                        type: switch (funcArg.def) {
                            case TypedExp(type, _):
                                Helpers.parseComplexType(type, funcArg);
                            default: null;
                        },
                        opt: opt
                    };
            };
        }

        var args:Array<FunctionArg> = switch (argList.def) {
            case ListExp(funcArgs):
                funcArgs.map(makeFuncArg);
            case CallExp(_, _):
                throw KissError.fromExp(argList, 'expected an argument list. Change the parens () to brackets []');
            default:
                throw KissError.fromExp(argList, 'expected an argument list');
        };

        var vars = [for (arg in args) {
            {
                name: arg.name,
                type: arg.type
            }
        }];

        for (v in vars) {
            k.addVarInScope(v, true);
        }

        var expr = if (body.length == 0) {
            EReturn(null).withMacroPosOf(if (name != null) name else argList);
        } else {
            var block = k.convert(CallExp(Symbol("begin").withPos(body[0].pos), body).withPos(body[0].pos));

            if (returnsValue) {
                EReturn(block).withMacroPosOf(body[-1]);
            } else {
                block;
            };
        }

        for (v in vars) {
            k.removeVarInScope(v, true);
        }

        // To make function args immutable by default, we would use (let...) instead of (begin...)
        // to make the body expression.
        // But setting null arguments to default values is so common, and arguments are not settable references,
        // so function args are not immutable.
        return {
            ret: if (name != null) Helpers.explicitType(name) else null,
            args: args,
            expr: expr,
            params: params
        };
    }

    // The name of this function is confusing--it actually makes a Haxe `case` expression, not a switch-case expression
    public static function makeSwitchCase(caseExp:ReaderExp, k:KissState):Case {
        var guard:Expr = null;
        var restExpIndex = -1;
        var restExpName = "";
        var expNames = [];
        var listVarSymbol = null;

        function makeSwitchPattern(patternExp:ReaderExp):Array<Expr> {
            return switch (patternExp.def) {
                case CallExp({pos: _, def: Symbol("when")}, whenExps):
                    patternExp.checkNumArgs(2, 2, "(when <guard> <pattern>)");
                    if (guard != null)
                        throw KissError.fromExp(caseExp, "case pattern can only have one `when` or `unless` guard");
                    guard = macro Prelude.truthy(${k.convert(whenExps[0])});
                    makeSwitchPattern(whenExps[1]);
                case CallExp({pos: _, def: Symbol("unless")}, whenExps):
                    patternExp.checkNumArgs(2, 2, "(unless <guard> <pattern>)");
                    if (guard != null)
                        throw KissError.fromExp(caseExp, "case pattern can only have one `when` or `unless` guard");
                    guard = macro !Prelude.truthy(${k.convert(whenExps[0])});
                    makeSwitchPattern(whenExps[1]);
                case ListEatingExp(exps) if (exps.length == 0):
                    throw KissError.fromExp(patternExp, "list-eating pattern should not be empty");
                case ListEatingExp(exps):
                    for (idx in 0...exps.length) {
                        var exp = exps[idx];
                        switch (exp.def) {
                            case Symbol(_) | MetaExp("mut", {pos: _, def: Symbol(_)}):
                                expNames.push(exp);
                            case ListRestExp(name):
                                if (restExpIndex > -1) {
                                    throw KissError.fromExp(patternExp, "list-eating pattern cannot have multiple ... or ...[restVar] expressions");
                                }
                                restExpIndex = idx;
                                restExpName = name;
                            default:
                                throw KissError.fromExp(exp, "list-eating pattern can only contain symbols, ..., or ...[restVar]");
                        }
                    }

                    if (restExpIndex == -1) {
                        throw KissError.fromExp(patternExp, "list-eating pattern is missing ... or ...[restVar]");
                    }

                    if (expNames.length == 0) {
                        throw KissError.fromExp(patternExp, "list-eating pattern must match at least one single element");
                    }

                    var b = patternExp.expBuilder();
                    listVarSymbol = b.symbol();
                    guard = k.convert(b.callSymbol(">", [b.field("length", listVarSymbol), b.raw(Std.string(expNames.length))]));
                    makeSwitchPattern(listVarSymbol);
                default:
                    [k.forCaseParsing().convert(patternExp)];
            }
        }

        return switch (caseExp.def) {
            case CallExp(patternExp, caseBodyExps):
                var pattern = makeSwitchPattern(patternExp);
                var b = caseExp.expBuilder();
                var body = if (restExpIndex == -1) {
                    k.convert(b.begin(caseBodyExps));
                } else {
                    var letBindings = [];
                    for (idx in 0...restExpIndex) {
                        letBindings.push(expNames.shift());
                        letBindings.push(b.callSymbol("nth", [listVarSymbol, b.raw(Std.string(idx))]));
                    }
                    if (restExpName == "") {
                        restExpName = "_";
                    }
                    letBindings.push(b.symbol(restExpName));
                    var sliceArgs = [b.raw(Std.string(restExpIndex))];
                    if (expNames.length > 0) {
                        sliceArgs.push(b.callSymbol("-", [b.field("length", listVarSymbol), b.raw(Std.string(expNames.length))]));
                    }
                    letBindings.push(b.call(b.field("slice", listVarSymbol), sliceArgs));
                    while (expNames.length > 0) {
                        var idx = b.callSymbol("-", [b.field("length", listVarSymbol), b.raw(Std.string(expNames.length))]);
                        letBindings.push(expNames.shift());
                        letBindings.push(b.callSymbol("nth", [listVarSymbol, idx]));
                    }
                    var letExp = b.callSymbol("let", [b.list(letBindings)].concat(caseBodyExps));
                    k.convert(letExp);
                };
                // These prints for debugging need to be wrapped in comments because they'll get picked up by convertToHScript()
                // Prelude.print('/* $pattern */');
                // Prelude.print('/* $body */');
                // Prelude.print('/* $guard */');
                {
                    values: pattern,
                    expr: body,
                    guard: guard
                };
            default:
                throw KissError.fromExp(caseExp, "case expressions for (case...) must take the form ([pattern] [body...])");
        }
    }

    /**
        Throw a KissError if the given expression has the wrong number of arguments
    **/
    public static function checkNumArgs(wholeExp:ReaderExp, min:Null<Int>, max:Null<Int>, ?expectedForm:String) {
        if (expectedForm == null) {
            expectedForm = if (max == min) {
                '$min arguments';
            } else if (max == null) {
                'at least $min arguments';
            } else if (min == null) {
                'no more than $max arguments';
            } else if (min == null && max == null) {
                throw 'checkNumArgs() needs a min or a max';
            } else {
                'between $min and $max arguments';
            };
        }

        var args = switch (wholeExp.def) {
            case CallExp(_, args): args;
            default: throw KissError.fromExp(wholeExp, "Can only check number of args in a CallExp");
        };

        if (min != null && args.length < min) {
            throw KissError.fromExp(wholeExp, 'Not enough arguments. Expected $expectedForm');
        } else if (max != null && args.length > max) {
            throw KissError.fromExp(wholeExp, 'Too many arguments. Expected $expectedForm');
        }
    }

    public static function removeTypeAnnotations(exp:ReaderExp):ReaderExp {
        var def = switch (exp.def) {
            case Symbol(_) | StrExp(_) | RawHaxe(_) | RawHaxeBlock(_) | Quasiquote(_):
                exp.def;
            case CallExp(func, callArgs):
                CallExp(removeTypeAnnotations(func), callArgs.map(removeTypeAnnotations));
            case ListExp(elements):
                ListExp(elements.map(removeTypeAnnotations));
            case TypedExp(type, innerExp):
                innerExp.def;
            case MetaExp(meta, innerExp):
                MetaExp(meta, removeTypeAnnotations(innerExp));
            case FieldExp(field, innerExp):
                FieldExp(field, removeTypeAnnotations(innerExp));
            case KeyValueExp(keyExp, valueExp):
                KeyValueExp(removeTypeAnnotations(keyExp), removeTypeAnnotations(valueExp));
            case Unquote(innerExp):
                Unquote(removeTypeAnnotations(innerExp));
            case UnquoteList(innerExp):
                UnquoteList(removeTypeAnnotations(innerExp));
            case None:
                None;
            default:
                throw KissError.fromExp(exp, 'cannot remove type annotations');
        };
        return def.withPosOf(exp);
    }
    // hscript.Interp is very finicky about some edge cases.
    // This function handles them
    private static function mapForInterp(expr:Expr):Expr {
        return expr.map(subExp -> {
            switch (subExp.expr) {
                case ETry(e, catches):
                    catches = [for (c in catches) {
                        // hscript.Parser expects :Dynamic after the catch varname
                        {
                            type: Helpers.parseComplexType("Dynamic"),
                            name: c.name,
                            expr: c.expr
                        };
                    }];
                    {
                        pos: subExp.pos,
                        expr: ETry(e, catches)
                    };
                default: mapForInterp(subExp);
            }
        });
    }

    static var parser = new Parser(); 
    static function compileTimeHScript(exp:ReaderExp, k:KissState) {
        var hscriptExp = mapForInterp(k.forMacroEval().convert(exp));
        var code = hscriptExp.toString(); // tink_macro to the rescue
        #if macrotest
        Prelude.print("Compile-time hscript: " + code);
        #end
        // Need parser external to the KissInterp to wrap parsing in an informative try-catch
        var parsed = try {
            parser.parseString(code);
        } catch (e) {
            throw KissError.fromExp(exp, 'macro-time hscript parsing failed with $e:\n$code');
        };
        return parsed;
    }

    public static function runAtCompileTimeDynamic(exp:ReaderExp, k:KissState, ?args:Map<String, Dynamic>):Dynamic {
        var parsed = compileTimeHScript(exp, k);
        
        // The macro interpreter gets everything a KissInterp has,
        // plus macro-specific things.
        var interp = new KissInterp();
        interp.variables.set("read", Reader.assertRead.bind(_, k));
        interp.variables.set("readExpArray", Reader.readExpArray.bind(_, _, k));
        interp.variables.set("ReaderExp", ReaderExpDef);
        interp.variables.set("nextToken", Reader.nextToken.bind(_, "a token"));
        interp.variables.set("printExp", printExp);
        interp.variables.set("kiss", {
            ReaderExp: {
                ReaderExpDef: ReaderExpDef
            },
            KissInterp: KissInterp,
            Prelude: Prelude
        });
        interp.variables.set("k", k.forMacroEval());
        interp.variables.set("Macros", Macros);
        interp.variables.set("Stream", Stream);
        for (name => value in k.macroVars) {
            interp.variables.set(name, value);
        }
        interp.variables.set("_setMacroVar", (name, value) -> {
            k.macroVars[name] = value;
            interp.variables.set(name, value);
        });
        interp.variables.set("KissError", KissError);

        function innerRunAtCompileTimeDynamic(innerExp:ReaderExp) {
            // in case macroVars have changed
            for (name => value in k.macroVars) {
                interp.variables.set(name, value);
            }
            var locals = interp.getLocals();
            interp.setLocals(new Cloner().clone(locals));
            var value = interp.publicExprReturn(compileTimeHScript(innerExp, k));
            interp.setLocals(locals);
            if (value == null) {
                throw KissError.fromExp(exp, "compile-time evaluation returned null");
            }
            return value;
        }
        function innerRunAtCompileTime(exp:ReaderExp) {
            var v:Dynamic = innerRunAtCompileTimeDynamic(exp);
            return compileTimeValueToReaderExp(v, exp);
        }

        interp.variables.set("eval", innerRunAtCompileTimeDynamic);
        interp.variables.set("Helpers", {
            evalUnquotes: evalUnquotes.bind(_, innerRunAtCompileTime),
            runAtCompileTime: innerRunAtCompileTime
        });
        interp.variables.set("__interp__", interp);

        if (args != null) {
            for (arg => value in args) {
                interp.variables.set(arg, value);
            }
        }
        var value:Dynamic = interp.execute(parsed);
        if (value == null) {
            throw KissError.fromExp(exp, "compile-time evaluation returned null");
        }
        return value;
    }

    public static function runAtCompileTime(exp:ReaderExp, k:KissState, ?args:Map<String, Dynamic>):ReaderExp {
        var value = runAtCompileTimeDynamic(exp, k, args);
        var expResult = compileTimeValueToReaderExp(value, exp);
        #if macrotest
        Prelude.print('Compile-time value: ${Reader.toString(expResult.def)}');
        #end
        return expResult;
    }

    // The value could be either a ReaderExp, ReaderExpDef, Array of ReaderExp/ReaderExpDefs, or something else entirely,
    // but it needs to be a ReaderExp for evalUnquotes()
    static function compileTimeValueToReaderExp(e:Dynamic, source:ReaderExp):ReaderExp {
        return if (Std.isOfType(e, Array)) {
            var arr:Array<Dynamic> = e;
            var listExps = arr.map(compileTimeValueToReaderExp.bind(_, source));
            ListExp(listExps).withPosOf(source);
        } else if (Std.isOfType(e, Float) || Std.isOfType(e, Int)) {
            Symbol(Std.string(e)).withPosOf(source);
        } else if (Std.isOfType(e, Bool)) {
            Symbol(Std.string(e)).withPosOf(source);
        } else if (Std.isOfType(e, String)) {
            var s:String = e;
            StrExp(s).withPosOf(source);
        } else if (Std.isOfType(e, ReaderExpDef)) {
            (e : ReaderExpDef).withPosOf(source);
        } else if (e.pos != null && e.def != null) {
            (e : ReaderExp);
        } else {
            throw KissError.fromExp(source, 'Value $e cannot be used as a Kiss expression');
        }
    }

    public static function printExp(e:Dynamic, label = "") {
        var toPrint = label;
        if (label.length > 0) {
            toPrint += ": ";
        }
        var expDef = if (e.def != null) e.def else e;
        toPrint += Reader.toString(expDef);
        Prelude.printStr(toPrint);
        return e;
    }

    static function evalUnquoteLists(l:Array<ReaderExp>, innerRunAtCompileTime:(ReaderExp)->Dynamic):Array<ReaderExp> {
        var idx = 0;
        while (idx < l.length) {
            switch (l[idx].def) {
                case UnquoteList(exp):
                    l.splice(idx, 1);
                    var listToInsert:Dynamic = innerRunAtCompileTime(exp);
                    // listToInsert could be either an array (from &rest) or a ListExp (from [list syntax])
                    var newElements:Array<ReaderExp> = if (Std.isOfType(listToInsert, Array)) {
                        listToInsert;
                    } else {
                        switch (listToInsert.def) {
                            case ListExp(elements):
                                elements;
                            default:
                                throw KissError.fromExp(listToInsert, ",@ can only be used with lists");
                        };
                    };
                    for (el in newElements) {
                        l.insert(idx++, el);
                    }
                default:
                    idx++;
            }
        }
        return l;
    }

    public static function evalUnquotes(exp:ReaderExp, innerRunAtCompileTime:(ReaderExp)->Dynamic):ReaderExp {
        var recurse = evalUnquotes.bind(_, innerRunAtCompileTime);
        var def = switch (exp.def) {
            case Symbol(_) | StrExp(_) | RawHaxe(_) | RawHaxeBlock(_):
                exp.def;
            case CallExp(func, callArgs):
                CallExp(recurse(func), evalUnquoteLists(callArgs, innerRunAtCompileTime).map(recurse));
            case ListExp(elements):
                ListExp(evalUnquoteLists(elements, innerRunAtCompileTime).map(recurse));
            case TypedExp(type, innerExp):
                TypedExp(type, recurse(innerExp));
            case FieldExp(field, innerExp):
                FieldExp(field, recurse(innerExp));
            case KeyValueExp(keyExp, valueExp):
                KeyValueExp(recurse(keyExp), recurse(valueExp));
            case Unquote(innerExp):
                var unquoteValue:Dynamic = innerRunAtCompileTime(innerExp);
                compileTimeValueToReaderExp(unquoteValue, exp).def;
            case MetaExp(meta, innerExp):
                MetaExp(meta, recurse(innerExp));
            default:
                throw KissError.fromExp(exp, 'unquote evaluation not implemented');
        };
        return def.withPosOf(exp);
    }

    // Return convenient functions for succinctly making new ReaderExps that link back to an original exp's
    // position in source code
    public static function expBuilder(posRef:ReaderExp) {
        function _symbol(?name:String) {
            return Prelude.symbol(name).withPosOf(posRef);
        }
        function call(func:ReaderExp, args:Array<ReaderExp>) {
            return CallExp(func, args).withPosOf(posRef);
        }
        function callSymbol(symbol:String, args:Array<ReaderExp>) {
            return call(_symbol(symbol), args);
        }
        function field(f:String, exp:ReaderExp) {
            return FieldExp(f, exp).withPosOf(posRef);
        }
        function list(exps:Array<ReaderExp>) {
            return ListExp(exps).withPosOf(posRef);
        }
        function objectWith (bindings:Array<ReaderExp>, captures:Array<ReaderExp>) {
            return callSymbol("objectWith", [list(bindings)].concat(captures));
        }
        function str(s:String) {
            return StrExp(s).withPosOf(posRef);
        }
        function raw(code:String) {
            return RawHaxe(code).withPosOf(posRef);
        }
        function int(v:Int) {
            return _symbol(Std.string(v));
        }
        function float(v:Float) {
            return _symbol(Std.string(v));
        }
        function let(bindings:Array<ReaderExp>, body:Array<ReaderExp>) {
            return callSymbol("let", [list(bindings)].concat(body));
        }
        function throwAssertOrNeverError(messageExp:ReaderExp) {
            var failureError = KissError.fromExp(posRef, "").toString(AssertionFail);
            var colonsInPrefix = if (Sys.systemName() == "Windows") 5 else 4;
            return callSymbol("throw", [
                callSymbol("kiss.Prelude.runtimeInsertAssertionMessage", [messageExp, str(failureError), int(colonsInPrefix)])
            ]);
        }
        return {
            call: call,
            callSymbol: callSymbol,
            callField: (fieldName:String, callOn:ReaderExp, args:Array<ReaderExp>) -> call(field(fieldName, callOn), args),
            print: (arg:ReaderExp) -> CallExp(Symbol("print").withPosOf(posRef), [arg]).withPosOf(posRef),
            the: (type:ReaderExp, value:ReaderExp) -> callSymbol("the", [type, value]),
            not: (exp:ReaderExp) -> callSymbol("not", [exp]),
            list: list,
            str: str,
            symbol: _symbol,
            int: int,
            float: float,
            raw: raw,
            typed: (path:String, exp:ReaderExp) -> TypedExp(path, exp).withPosOf(posRef),
            meta: (m:String, exp:ReaderExp) -> MetaExp(m, exp).withPosOf(posRef),
            field: field,
            keyValue: (key:ReaderExp, value:ReaderExp) -> KeyValueExp(key, value).withPosOf(posRef),
            begin: (exps:Array<ReaderExp>) -> callSymbol("begin", exps),
            set: (v:ReaderExp, value:ReaderExp) -> callSymbol("set", [v, value]),
            let: let,
            objectWith: objectWith,
            // Only use within assertion macros
            throwAssertionError: () -> {
                var usage = "throwAssertionError can only be used in a builder of an assertion macro";
                var exps = switch (posRef.def) {
                    case CallExp(_, exps):
                        exps;
                    default:
                        throw KissError.fromExp(_symbol("throwAssertionError"), usage);
                }
                var messageExp = if (exps.length > 1) {
                    exps[1];
                } else {
                    str("");
                };
                throwAssertOrNeverError(messageExp);
            },
            neverCase: () -> {
                switch (posRef.def) {
                    case CallExp({pos: _, def: Symbol("never")}, neverExps):
                        posRef.checkNumArgs(1, 1, '(never <pattern>)');
                        call(neverExps[0], [
                            throwAssertOrNeverError(str('case should never match pattern ${Reader.toString(neverExps[0].def)}'))
                        ]);
                    default:
                        posRef;
                }
            },
            // Compile-time only!
            throwKissError: (reason:String) -> {
                callSymbol("throw", [
                    callSymbol("KissError.fromExpStr", [
                        // pos
                        objectWith([
                            _symbol("file"), str(posRef.pos.file),
                            _symbol("line"), int(posRef.pos.line),
                            _symbol("column"), int(posRef.pos.column),
                            _symbol("absoluteChar"), int(posRef.pos.absoluteChar),
                        ], []),
                        // expStr
                        str(Reader.toString(posRef.def)),
                        str(reason)
                    ])
                ]);
            },
            haxeExpr: (e:haxe.macro.Expr) -> withMacroPosOf(e.expr, posRef),
            none: () -> None.withPosOf(posRef)
        };
    }

    public static function checkNoEarlyOtherwise(cases:kiss.List<ReaderExp>) {
        for (i in 0...cases.length) {
            switch (cases[i].def) {
                case CallExp({pos: _, def: Symbol("otherwise")}, _) if (i != cases.length - 1):
                    throw KissError.fromExp(cases[i], "(otherwise <body...>) branch must come last in a (case <...>) expression");
                default:
            }
        }
    }

    public static function argList(exp:ReaderExp, forThis:String, allowEmpty = true):Array<ReaderExp> {
        return switch (exp.def) {
            case ListExp([]) if (allowEmpty):
                [];
            case ListExp([]) if (!allowEmpty):
                throw KissError.fromExp(exp, 'arg list for $forThis must not be empty');
            case ListExp(argExps):
                argExps;
            default:
                throw KissError.fromExp(exp, '$forThis arg list should be a list expression');
        };
    }

    public static function bindingList(exp:ReaderExp, forThis:String, allowEmpty = false):Array<ReaderExp> {
        return switch (exp.def) {
            case ListExp(bindingExps) if ((allowEmpty || bindingExps.length > 0) && bindingExps.length % 2 == 0):
                bindingExps;
            default:
                throw KissError.fromExp(exp, '$forThis bindings should be a list expression with an even number of sub expressions (at least 2)');
        };
    }
}
