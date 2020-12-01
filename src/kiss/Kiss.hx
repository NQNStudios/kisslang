package kiss;

#if macro
import haxe.Exception;
import haxe.macro.Context;
import haxe.macro.Expr;
import kiss.Stream;
import kiss.Reader;
import kiss.FieldForms;
import kiss.SpecialForms;
import kiss.Macros;
import kiss.CompileError;

using kiss.Helpers;
using kiss.Reader;
using tink.MacroApi;

typedef ExprConversion = (ReaderExp) -> Expr;

typedef KissState = {
    className:String,
    readTable:Map<String, ReadFunction>,
    fieldForms:Map<String, FieldFormFunction>,
    specialForms:Map<String, SpecialFormFunction>,
    macros:Map<String, MacroFunction>,
    convert:ExprConversion
};

class Kiss {
    /**
        Build a Haxe class from a corresponding .kiss file
    **/
    macro static public function build(kissFile:String):Array<Field> {
        try {
            var classFields = Context.getBuildFields();
            var className = Context.getLocalClass().get().name;

            var stream = new Stream(kissFile);

            var k = {
                className: className,
                readTable: Reader.builtins(),
                fieldForms: FieldForms.builtins(),
                specialForms: SpecialForms.builtins(),
                macros: Macros.builtins(),
                convert: null
            }
            k.convert = readerExpToHaxeExpr.bind(_, k);

            // Helpful aliases
            k.defAlias("print", "Prelude.print");
            k.defAlias("map", "Lambda.map");
            k.defAlias("filter", "Lambda.filter");
            k.defAlias("has", "Lambda.has");

            while (true) {
                stream.dropWhitespace();
                if (stream.isEmpty())
                    break;
                var position = stream.position();
                var nextExp = Reader.read(stream, k.readTable);

                // The last expression might be a comment, in which case None will be returned
                switch (nextExp) {
                    case Some(nextExp):
                        #if test
                        Sys.println(nextExp.def.toString());
                        #end
                        var field = readerExpToField(nextExp, k);
                        if (field != null)
                            classFields.push(field);
                    case None:
                        stream.dropWhitespace(); // If there was a comment, drop whitespace that comes after
                }
            }

            return classFields;
        } catch (err:CompileError) {
            Sys.println(err);
            Sys.exit(1);
            return null; // Necessary for build() to compile
        } catch (err:Exception) {
            throw err; // Re-throw haxe exceptions for precise stacks
        }
    }

    static function readerExpToField(exp:ReaderExp, k:KissState):Null<Field> {
        var fieldForms = k.fieldForms;

        // Macros at top-level are allowed if they expand into a fieldform, or null like defreadermacro
        var macros = k.macros;

        return switch (exp.def) {
            case CallExp({pos: _, def: Symbol(mac)}, args) if (macros.exists(mac)):
                var expandedExp = macros[mac](exp, args, k);
                if (expandedExp != null) readerExpToField(macros[mac](expandedExp, args, k), k) else null;
            case CallExp({pos: _, def: Symbol(formName)}, args) if (fieldForms.exists(formName)):
                fieldForms[formName](exp, args, k);
            default:
                throw CompileError.fromExp(exp, 'invalid valid field form');
        };
    }

    static function readerExpToHaxeExpr(exp:ReaderExp, k:KissState):Expr {
        var macros = k.macros;
        var specialForms = k.specialForms;
        // Bind the table arguments of this function for easy recursive calling/passing
        var convert = readerExpToHaxeExpr.bind(_, k);
        var expr = switch (exp.def) {
            case Symbol(name):
                Context.parse(name, exp.macroPos());
            case StrExp(s):
                EConst(CString(s)).withMacroPosOf(exp);
            case CallExp({pos: _, def: Symbol(mac)}, args) if (macros.exists(mac)):
                convert(macros[mac](exp, args, k));
            case CallExp({pos: _, def: Symbol(specialForm)}, args) if (specialForms.exists(specialForm)):
                specialForms[specialForm](exp, args, k);
            case CallExp(func, args):
                ECall(convert(func), [for (argExp in args) convert(argExp)]).withMacroPosOf(exp);

            /*
                // Typed expressions in the wild become casts:
                case TypedExp(type, innerExp):
                    ECast(convert(innerExp), if (type.length > 0) Helpers.parseComplexType(type, exp) else null).withMacroPosOf(wholeExp);
             */
            case ListExp(elements):
                ENew({
                    pack: ["kiss"],
                    name: "List"
                }, [
                    EArrayDecl([for (elementExp in elements) convert(elementExp)]).withMacroPosOf(exp)
                ]).withMacroPosOf(exp);
            case RawHaxe(code):
                Context.parse(code, exp.macroPos());
            default:
                throw CompileError.fromExp(exp, 'conversion not implemented');
        };
        #if test
        Sys.println(expr.toString());
        #end
        return expr;
    }
}
#end
