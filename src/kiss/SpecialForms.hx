package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import kiss.Reader;
import kiss.Types;

using kiss.Helpers;
using kiss.Prelude;

// Special forms convert Kiss reader expressions into Haxe macro expressions
typedef SpecialFormFunction = (args:Array<ReaderExp>, convert:ExprConversion) -> Expr;

class SpecialForms {
    public static function builtins() {
        var map:Map<String, SpecialFormFunction> = [];

        map["begin"] = (args:Array<ReaderExp>, convert:ExprConversion) -> {
            pos: Context.currentPos(),
            expr: EBlock([for (bodyExp in args) convert(bodyExp)])
        };

        map["nth"] = (args:Array<ReaderExp>, convert:ExprConversion) -> {
            pos: Context.currentPos(),
            expr: EArray(convert(args[0]), convert(args[1]))
        };

        // TODO first through tenth

        // TODO special form for object declaration

        map["new"] = (args:Array<ReaderExp>, convert:ExprConversion) -> {
            if (args.length < 1) {
                throw '(new [type] constructorArgs...) is missing a type!';
            }
            var classType = switch (args[0]) {
                case Symbol(name): name;
                default: throw 'first arg in (new [type] ...) should be a class to instantiate';
            };
            ENew(Helpers.parseTypePath(classType), args.slice(1).map(convert)).withPos();
        };

        // TODO special form for assignment

        // TODO special form for local var declaration

        map["let"] = (args:Array<ReaderExp>, convert:ExprConversion) -> {
            var bindingList = switch (args[0]) {
                case ListExp(bindingExps) if (bindingExps.length > 0 && bindingExps.length % 2 == 0):
                    bindingExps;
                default:
                    throw '${args[0]} should be a list expression with an even number of sub expressions';
            };
            var bindingPairs = bindingList.groups(2);
            var varDefs = [
                for (bindingPair in bindingPairs)
                    {
                        name: switch (bindingPair[0]) {
                            case Symbol(name) | TypedExp(_, Symbol(name)):
                                name;
                            default:
                                throw 'first element of binding pair $bindingPair should be a symbol or typed symbol';
                        },
                        type: switch (bindingPair[0]) {
                            case TypedExp(type, _):
                                Helpers.parseComplexType(type);
                            default: null;
                        },
                        isFinal: true, // Let's give (let...) variable immutability a try
                        expr: convert(bindingPair[1])
                    }
            ];

            var body = args.slice(1);
            if (body.length == 0) {
                throw '(let....) expression with bindings $bindingPairs needs a body';
            }

            EBlock([EVars(varDefs).withPos(), EBlock(body.map(convert)).withPos()]).withPos();
        };

        // TODO special form for lambda

        // TODO special form for for loop
        // TODO special form for list comprehension
        // ^It would be nice if these were both DRY and supported list and keyvalue unpacking

        // TODO special form for while loop

        // TODO special form for do-while loop

        // TODO special form for switch

        // Type check syntax:
        map["the"] = (args:Array<ReaderExp>, convert:ExprConversion) -> {
            if (args.length != 2) {
                throw '(the [type] [value]) expression has wrong number of arguments: ${args.length}';
            }
            ECheckType(convert(args[1]), switch (args[0]) {
                case Symbol(type): Helpers.parseComplexType(type);
                default: throw 'first argument to (the... ) should be a valid type';
            }).withPos();
        };

        map["try"] = (args:Array<ReaderExp>, convert:ExprConversion) -> {
            if (args.length == 0) {
                throw '(try...) expression has nothing to try';
            }
            var tryKissExp = args[0];
            var catchKissExps = args.slice(1);
            ETry(convert(tryKissExp), [
                for (catchKissExp in catchKissExps) {
                    switch (catchKissExp) {
                        case CallExp(Symbol("catch"), catchArgs):
                            {
                                name: switch (catchArgs[0]) {
                                    case ListExp([Symbol(name) | TypedExp(_, Symbol(name))]): name;
                                    default: throw 'first argument to (catch... ) should be a one-element argument list, not ${catchArgs[0]}';
                                },
                                type: switch (catchArgs[0]) {
                                    case ListExp([TypedExp(type, _)]):
                                        Helpers.parseComplexType(type);
                                    default: null;
                                },
                                expr: convert(CallExp(Symbol("begin"), catchArgs.slice(1)))
                            };
                        default:
                            throw 'expressions following the first expression in a (try... ) should all be (catch... ) expressions, but you used $catchKissExp';
                    }
                }
            ]).withPos();
        };

        map["throw"] = (args:Array<ReaderExp>, convert:ExprConversion) -> {
            if (args.length != 1) {
                throw 'throw expression should only throw one value, not: $args';
            }
            EThrow(convert(args[0])).withPos();
        };

        map["<"] = foldComparison("_min");
        map["<="] = foldComparison("min");
        map[">"] = foldComparison("_max");
        map[">="] = foldComparison("max");
        map["="] = foldComparison("_eq");

        map["if"] = (args:Array<ReaderExp>, convert:ExprConversion) -> {
            if (args.length < 2 || args.length > 3) {
                throw '(if...) expression has wrong number of arguments: ${args.length}';
            }

            var condition = macro Prelude.truthy(${convert(args[0])});
            var thenExp = convert(args[1]);
            var elseExp = if (args.length > 2) convert(args[2]) else null;

            EIf(condition, thenExp, elseExp).withPos();
        };

        // TODO cond

        return map;
    }

    static function foldComparison(func:String) {
        return (args:Array<ReaderExp>, convert:ExprConversion) -> {
            pos: Context.currentPos(),
            expr: EBinop(OpEq, convert(args[0]), convert(CallExp(Symbol(func), args)))
        };
    }
}
