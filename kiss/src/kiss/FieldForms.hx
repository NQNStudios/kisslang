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
    public static function addBuiltins(k:KissState) {
        var map:Map<String, FieldFormFunction> = [];

        function renameAndDeprecate(oldName:String, newName:String) {
            var form = map[oldName];
            map[oldName] = (wholeExp, args, k) -> {
                CompileError.warnFromExp(wholeExp, '$oldName has been renamed to $newName and deprecated');
                form(wholeExp, args, k);
            }
            map[newName] = form;
            k.formDocs[newName] = k.formDocs[oldName];
        }

        varOrProperty("var", k);
        varOrProperty("prop", k);

        funcOrMethod("function", k);
        funcOrMethod("method", k);

        return map;
    }

    static function fieldAccess(formName:String, fieldName:String, nameExp:ReaderExp, ?access:Array<Access>) {
        if (access == null) {
            access = if (["defvar", "defprop", "var", "prop"].indexOf(formName) != -1) {
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
            case MetaExp("public", nameExp):
                access.push(APublic);
                fieldAccess(formName, fieldName, nameExp, access);
            case MetaExp("private", nameExp):
                access.push(APrivate);
                fieldAccess(formName, fieldName, nameExp, access);
            default:
                if (["defvar", "defun", "var", "function"].indexOf(formName) != -1) {
                    access.push(AStatic);
                }
                // If &public or &private is not used, a shortcut to make a private field is
                // to start its name with _
                if (access.indexOf(APrivate) == -1 && access.indexOf(APublic) == -1) {
                    access.push(if (fieldName.startsWith("_")) APrivate else APublic);
                }
                access;
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

    static function varOrProperty(formName:String, k:KissState) {
        k.doc(formName, 1, 3, '($formName [optional: &mut] [optional :type] [variable] [optional value])');
        k.fieldForms[formName] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            var name = Helpers.varName(formName, args[0]);
            var access = fieldAccess(formName, name, args[0]);

            ({
                name: name,
                access: access,
                kind: FVar(Helpers.explicitType(args[0]), if (args.length > 1) k.convert(args[1]) else null),
                pos: wholeExp.macroPos()
            } : Field);
        }
    }

    static function funcOrMethod(formName:String, k:KissState) {
        k.doc(formName, 2, null, '($formName [optional &dynamic] [optional :type] [name] [[argNames...]] [body...])');
        k.fieldForms[formName] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {

            var name = Helpers.varName(formName, args[0]);
            var access = fieldAccess(formName, name, args[0]);
            var inStaticFunction = access.indexOf(AStatic) != -1;
            var returnsValue = !isVoid(args[0]);

            var wasInStatic = k.inStaticFunction;

            var f:Field = {
                name: name,
                access: access,
                kind: FFun(
                    Helpers.makeFunction(
                        args[0],
                        returnsValue,
                        args[1],
                        args.slice(2),
                        k.forStaticFunction(inStaticFunction),
                        formName)),
                pos: wholeExp.macroPos()
            };

            k = k.forStaticFunction(wasInStatic);
            return f;
        }
    }
}
