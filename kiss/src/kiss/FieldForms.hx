package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;
import kiss.Reader;
import kiss.Helpers;
import kiss.Stream;
import kiss.CompileError;
import kiss.Kiss;

using kiss.Kiss;
using kiss.Helpers;
using kiss.Reader;
using StringTools;

// Field forms convert Kiss reader expressions into Haxe macro class fields
typedef FieldFormFunction = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> Field;

class FieldForms {
    public static function builtins() {
        var map:Map<String, FieldFormFunction> = [];

        map["defvar"] = varOrProperty.bind("defvar");
        map["defprop"] = varOrProperty.bind("defprop");

        map["defun"] = funcOrMethod.bind("defun");
        map["defmethod"] = funcOrMethod.bind("defmethod");

        return map;
    }

    static function fieldAccess(formName:String, fieldName:String, nameExp:ReaderExp, ?access:Array<Access>) {
        if (access == null) {
            access = if (formName == "defvar" || formName == "defprop") {
                [AFinal];
            } else {
                [];
            };
        }
        // AMacro access is not allowed because it wouldn't make sense to write Haxe macros in Kiss
        // when you can write Kiss macros which are just as powerful
        return switch (nameExp.def) {
            case MetaExp("mut", nameExp):
                access.remove(AFinal);
                fieldAccess(formName, fieldName, nameExp, access);
            case MetaExp("override", nameExp):
                access.push(AOverride);
                fieldAccess(formName, fieldName, nameExp, access);
            case MetaExp("dynamic", nameExp):
                access.push(ADynamic);
                fieldAccess(formName, fieldName, nameExp, access);
            case MetaExp("inline", nameExp):
                access.push(AInline);
                fieldAccess(formName, fieldName, nameExp, access);
            case MetaExp("final", nameExp):
                access.push(AFinal);
                fieldAccess(formName, fieldName, nameExp, access);
            default:
                if (formName == "defvar" || formName == "defun") {
                    access.push(AStatic);
                }
                access.push(if (fieldName.startsWith("_")) APrivate else APublic);
                access;
        };
    }

    static function fieldName(formName:String, nameExp:ReaderExp) {
        return switch (nameExp.def) {
            case Symbol(name):
                name;
            case MetaExp(_, nameExp) | TypedExp(_, nameExp):
                fieldName(formName, nameExp);
            default:
                throw CompileError.fromExp(nameExp, 'The first argument to $formName should be a variable name, :Typed variable name, and/or &meta variable name.');
        };
    }

    static function isVoid(nameExp:ReaderExp) {
        return switch (nameExp.def) {
            case MetaExp(_, nameExp):
                isVoid(nameExp);
            case TypedExp("Void", _) | Symbol("new"):
                true;
            default:
                false;
        }
    }

    static function varOrProperty(formName:String, wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState):Field {
        wholeExp.checkNumArgs(1, 3, '($formName [optional: &mut] [optional :type] [variable] [optional value])');

        var name = fieldName(formName, args[0]);
        var access = fieldAccess(formName, name, args[0]);

        return {
            name: name,
            access: access,
            kind: FVar(switch (args[0].def) {
                case TypedExp(type, _):
                    Helpers.parseComplexType(type, args[0]);
                default: null;
            }, if (args.length > 1) k.convert(args[1]) else null),
            pos: wholeExp.macroPos()
        };
    }

    static function funcOrMethod(formName:String, wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState):Field {
        wholeExp.checkNumArgs(3, null, '($formName [optional :type] [name] [[argNames...]] [body...])');

        var name = fieldName(formName, args[0]);
        var access = fieldAccess(formName, name, args[0]);
        var returnsValue = !isVoid(args[0]);

        return {
            name: name,
            access: access,
            kind: FFun(Helpers.makeFunction(args[0], returnsValue, args[1], args.slice(2), k)),
            pos: wholeExp.macroPos()
        };
    }
}
