package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.PositionTools;
import kiss.Reader;
import kiss.CompileError;
import kiss.Kiss;
import kiss.SpecialForms;

using kiss.Reader;
using kiss.Helpers;
using kiss.Kiss;
using StringTools;

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

    public static function parseTypePath(path:String, from:ReaderExp):TypePath {
        // TODO function types with generic argument types are broken
        var genericParts = path.split("<");
        var typeParams:Array<TypeParam> = null;
        if (genericParts.length > 1) {
            typeParams = [
                for (typeParam in genericParts[1].substr(0, genericParts[1].length - 1).split(",")) {
                    TPType(parseComplexType(typeParam, from));
                }
            ];
        }

        var parts:List<String> = genericParts[0].trim().split(".");
        var uppercaseParts:List<Bool> = parts.map(startsWithUpperCase);
        for (isUpcase in uppercaseParts.slice(0, -2)) {
            if (isUpcase) {
                throw CompileError.fromExp(from, 'Type path $path should only have capitalized type and subtype');
            }
        }
        var lastIsCap = uppercaseParts[-1];
        var penultIsCap = uppercaseParts[-2];

        return if (penultIsCap && lastIsCap) {
            {
                sub: parts[-1],
                name: parts[-2],
                pack: parts.slice(0, -2),
                params: typeParams
            };
        } else if (lastIsCap) {
            {
                name: parts[-1],
                pack: parts.slice(0, -1),
                params: typeParams
            };
        } else {
            throw CompileError.fromExp(from, 'Type path $path should end with a capitalized type');
        };
    }

    public static function parseComplexType(path:String, from:ReaderExp):ComplexType {
        return TPath(parseTypePath(path, from));
    }

    // TODO generic type parameter declarations
    public static function makeFunction(?name:ReaderExp, argList:ReaderExp, body:List<ReaderExp>, k:KissState):Function {
        var funcName = if (name != null) {
            switch (name.def) {
                case Symbol(name) | TypedExp(_, {pos: _, def: Symbol(name)}):
                    name;
                default:
                    throw CompileError.fromExp(name, 'function name should be a symbol or typed symbol');
            };
        } else {
            "";
        };

        var numArgs = 0;
        // Once the &opt meta appears, all following arguments are optional until &rest
        var opt = false;
        // Once the &rest meta appears, no other arguments can be declared
        var rest = false;
        var restProcessed = false;

        function makeFuncArg(funcArg:ReaderExp):FunctionArg {
            if (restProcessed) {
                throw CompileError.fromExp(funcArg, "cannot declare more arguments after a &rest argument");
            }
            return switch (funcArg.def) {
                case MetaExp("rest", innerFuncArg):
                    if (funcName == "") {
                        throw CompileError.fromExp(funcArg, "lambda does not support &rest arguments");
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
                        name: switch (funcArg.def) {
                            case Symbol(name) | TypedExp(_, {pos: _, def: Symbol(name)}):
                                name;
                            default:
                                throw CompileError.fromExp(funcArg, 'function argument should be a symbol or typed symbol');
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

        // To make function args immutable by default, we would use (let...) instead of (begin...)
        // to make the body expression.
        // But setting default arguments is so common, and arguments are not settable references,
        // so function args are not immutable.
        return {
            ret: if (name != null) switch (name.def) {
                case TypedExp(type, _): Helpers.parseComplexType(type, name);
                default: null;
            } else null,
            args: switch (argList.def) {
                case ListExp(funcArgs):
                    funcArgs.map(makeFuncArg);
                case CallExp(_, _):
                    throw CompileError.fromExp(argList, 'expected an argument list. Change the parens () to brackets []');
                default:
                    throw CompileError.fromExp(argList, 'expected an argument list');
            },
            expr: EReturn(k.convert(CallExp(Symbol("begin").withPos(body[0].pos), body).withPos(body[0].pos))).withMacroPosOf(body[-1])
        }
    }

    // alias replacements are processed by the reader
    public static function defAlias(k:KissState, whenItsThis:String, makeItThisInstead:ReaderExpDef) {
        // The alias has to be followed by a terminator to count!
        for (terminator in Reader.terminators) {
            k.readTable[whenItsThis + terminator] = (s:Stream) -> {
                s.putBackString(terminator);
                makeItThisInstead;
            }
        }
    }

    /**
        Throw a CompileError if the given expression has the wrong number of arguments
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
            default: throw CompileError.fromExp(wholeExp, "Can only check number of args in a CallExp");
        };

        if (min != null && args.length < min) {
            throw CompileError.fromExp(wholeExp, 'Not enough arguments. Expected $expectedForm');
        } else if (max != null && args.length > max) {
            throw CompileError.fromExp(wholeExp, 'Too many arguments. Expected $expectedForm');
        }
    }
}
