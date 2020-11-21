package kiss;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import kiss.Stream;
import kiss.Reader;
import kiss.FieldForms;
import kiss.SpecialForms;
import kiss.Macros;
import kiss.Types;

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

        while (true) {
            stream.dropWhitespace();
            if (stream.isEmpty())
                break;
            var position = stream.position();
            var nextExp = Reader.read(stream, k.readTable);
            #if test
            trace(nextExp);
            #end
            // The last expression might be a comment, in which case None will be returned
            switch (nextExp) {
                case Some(nextExp):
                    var field = readerExpToField(nextExp, position, k);
                    if (field != null)
                        classFields.push(field);
                case None:
                    stream.dropWhitespace(); // If there was a comment, drop whitespace that comes after
            }
        }

        return classFields;
    }

    static function readerExpToField(exp:ReaderExp, position:String, k:KissState):Null<Field> {
        var fieldForms = k.fieldForms;

        // Macros at top-level are allowed if they expand into a fieldform, or null like defreadermacro
        var macros = k.macros;

        return switch (exp) {
            case CallExp(Symbol(mac), args) if (macros.exists(mac)):
                var expandedExp = macros[mac](args, k);
                if (expandedExp != null) readerExpToField(macros[mac](args, k), position, k) else null;
            case CallExp(Symbol(formName), args) if (fieldForms.exists(formName)):
                fieldForms[formName](position, args, readerExpToHaxeExpr.bind(_, k));
            default:
                throw '$exp at $position is not a valid field form';
        };
    }

    static function readerExpToHaxeExpr(exp:ReaderExp, k:KissState):Expr {
        var macros = k.macros;
        var specialForms = k.specialForms;
        // Bind the table arguments of this function for easy recursive calling/passing
        var convert = readerExpToHaxeExpr.bind(_, k);
        var expr = switch (exp) {
            case Symbol(name):
                Context.parse(name, Context.currentPos());
            case StrExp(s):
                {
                    pos: Context.currentPos(),
                    expr: EConst(CString(s))
                };
            case CallExp(Symbol(mac), args) if (macros.exists(mac)):
                convert(macros[mac](args, k));
            case CallExp(Symbol(specialForm), args) if (specialForms.exists(specialForm)):
                specialForms[specialForm](args, convert);
            case CallExp(func, body):
                {
                    pos: Context.currentPos(),
                    expr: ECall(convert(func), [for (bodyExp in body) convert(bodyExp)])
                };
            case ListExp(elements):
                {
                    pos: Context.currentPos(),
                    expr: ENew({
                        pack: ["kiss"],
                        name: "List"
                    }, [
                        {
                            pos: Context.currentPos(),
                            expr: EArrayDecl([for (elementExp in elements) convert(elementExp)])
                        }
                    ])
                }
            case RawHaxe(code):
                Context.parse(code, Context.currentPos());
            default:
                throw 'cannot convert $exp yet';
        };
        #if test
        trace(expr.expr);
        #end
        return expr;
    }
}
#end
