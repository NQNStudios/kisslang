package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import kiss.Reader;
import kiss.Types;
import kiss.Helpers;

using StringTools;

// Field forms convert Kiss reader expressions into Haxe macro class fields
typedef FieldFormFunction = (position:String, args:Array<ReaderExp>, convert:ExprConversion) -> Field;

class FieldForms {
    public static function builtins() {
        var map:Map<String, FieldFormFunction> = [];

        map["defvar"] = varOrProperty.bind("defvar");
        map["defprop"] = varOrProperty.bind("defprop");

        map["defun"] = funcOrMethod.bind("defun");
        map["defmethod"] = funcOrMethod.bind("defmethod");

        return map;
    }

    static function fieldAccess(formName:String, fieldName:String) {
        var access = [];
        if (formName == "defvar" || formName == "defun") {
            access.push(AStatic);
        }
        access.push(if (fieldName.startsWith("_")) APrivate else APublic);
        return access;
    }

    static function fieldName(formName:String, position:String, nameExp:ReaderExp) {
        return switch (nameExp) {
            case Symbol(name) | TypedExp(_, Symbol(name)):
                name;
            default:
                throw 'The first argument to $formName at $position should be a variable name or typed variable name';
        };
    }

    static function varOrProperty(formName:String, position:String, args:Array<ReaderExp>, convert:ExprConversion):Field {
        if (args.length != 2) {
            throw '$formName with $args at $position is not a valid field definition';
        }

        var name = fieldName(formName, position, args[0]);
        var access = fieldAccess(formName, name);

        return {
            name: name,
            access: access,
            kind: FVar(switch (args[0]) {
                case TypedExp(type, _):
                    Helpers.parseComplexType(type);
                default: null;
            }, convert(args[1])),
            pos: Context.currentPos()
        };
    }

    // TODO &rest, &body and &optional arguments
    static function funcOrMethod(formName:String, position:String, args:Array<ReaderExp>, convert:ExprConversion):Field {
        if (args.length <= 2) {
            throw '$formName with $args is not a valid function/method definition';
        }

        var name = fieldName(formName, position, args[0]);
        var access = fieldAccess(formName, name);

        return {
            name: name,
            access: access,
            // TODO type parameter declarations
            kind: FFun({
                args: switch (args[1]) {
                    case ListExp(funcArgs):
                        [
                            // TODO optional arguments, default values
                            for (funcArg in funcArgs)
                                {
                                    name: switch (funcArg) {
                                        case Symbol(name) | TypedExp(_, Symbol(name)):
                                            name;
                                        default:
                                            throw '$funcArg should be a symbol or typed symbol for a function argument';
                                    },
                                    type: switch (funcArg) {
                                        case TypedExp(type, _):
                                            Helpers.parseComplexType(type);
                                        default: null;
                                    }
                                }
                        ];
                    case CallExp(_, _):
                        throw '${args[1]} should be an argument list. Change the parens () to brackets []';
                    default:
                        throw '${args[1]} should be an argument list';
                },
                ret: switch (args[0]) {
                    case TypedExp(type, _): Helpers.parseComplexType(type);
                    default: null;
                },
                expr: {
                    pos: Context.currentPos(),
                    expr: EReturn(convert(CallExp(Symbol("begin"), args.slice(2))))
                }
            }),
            pos: Context.currentPos()
        };
    }
}
