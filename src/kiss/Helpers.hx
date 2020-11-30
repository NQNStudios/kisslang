package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import kiss.Reader;
import kiss.CompileError;
import kiss.Kiss;

using kiss.Reader;
using kiss.Helpers;
using StringTools;

class Helpers {
    public static function withContextPos(e:ExprDef):Expr {
        return {
            pos: Context.currentPos(),
            expr: e
        };
    }

    static function startsWithUpperCase(s:String) {
        return s.charAt(0) == s.charAt(0).toUpperCase();
    }

    // TODO this doesn't parse generic typeparams yet
    public static function parseTypePath(path:String, from:ReaderExp):TypePath {
        var parts:List<String> = path.split(".");
        var uppercaseParts:List<Bool> = parts.map(startsWithUpperCase);
        for (isUpcase in uppercaseParts.slice(0, -2)) {
            if (isUpcase) {
                throw CompileError.fromExp(from, 'Type path $path should only have capitalized type and subtype');
            }
        }
        var lastIsCap = uppercaseParts[-1];
        var penultIsCap = uppercaseParts[-2];

        return if (lastIsCap && penultIsCap) {
            {
                sub: parts[-1],
                name: parts[-2],
                pack: parts.slice(0, -2)
            };
        } else if (lastIsCap) {
            {
                name: parts[-1],
                pack: parts.slice(0, -1)
            };
        } else {
            throw CompileError.fromExp(from, 'Type path $path should end with a capitalized type');
        };
    }

    public static function parseComplexType(path:String, from:ReaderExp):ComplexType {
        return TPath(parseTypePath(path, from));
    }

    // TODO generic type parameter declarations

    public static function makeFunction(?name:ReaderExp, argList:ReaderExp, body:Array<ReaderExp>, k:KissState):Function {
        return {
            ret: if (name != null) switch (name.def) {
                case TypedExp(type, _): Helpers.parseComplexType(type, name);
                default: null;
            } else null,
            args: switch (argList.def) {
                case ListExp(funcArgs):
                    [
                        // TODO optional arguments, rest arguments
                        // ^ rest arguments will have to define a macro with the function's name that wraps the rest args in a list when calling it from Kiss
                        for (funcArg in funcArgs)
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
                                }
                            }
                    ];
                case CallExp(_, _):
                    throw CompileError.fromExp(argList, 'expected an argument list. Change the parens () to brackets []');
                default:
                    throw CompileError.fromExp(argList, 'expected an argument list');
            },
            expr: EReturn(k.convert(CallExp(Symbol("begin").withPos(body[0].pos), body).withPos(body[0].pos))).withContextPos()
        }
    }

    // alias replacements are processed by the reader
    public static function defAlias(k:KissState, whenItsThis:String, makeItThisInstead:String) {
        k.readTable[whenItsThis] = (_:Stream) -> Symbol(makeItThisInstead);
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
