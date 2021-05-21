package kiss;

#if macro
import haxe.Exception;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.io.Path;
import kiss.Stream;
import kiss.Reader;
import kiss.ReaderExp;
import kiss.FieldForms;
import kiss.SpecialForms;
import kiss.Macros;
import kiss.CompileError;
import kiss.cloner.Cloner;

using kiss.Helpers;
using kiss.Reader;
using tink.MacroApi;
using haxe.io.Path;

typedef ExprConversion = (ReaderExp) -> Expr;

typedef KissState = {
    className:String,
    readTable:ReadTable,
    startOfLineReadTable:ReadTable,
    fieldForms:Map<String, FieldFormFunction>,
    specialForms:Map<String, SpecialFormFunction>,
    macros:Map<String, MacroFunction>,
    wrapListExps:Bool,
    loadedFiles:Map<String, Bool>,
    callAliases:Map<String, ReaderExpDef>,
    identAliases:Map<String, ReaderExpDef>,
    fields:Array<Field>,
    loadingDirectory:String,
    hscript:Bool
};

class Kiss {
    public static function defaultKissState():KissState {
        var className = Context.getLocalClass().get().name;

        var k = {
            className: className,
            readTable: Reader.builtins(),
            startOfLineReadTable: new ReadTable(),
            fieldForms: FieldForms.builtins(),
            specialForms: SpecialForms.builtins(),
            macros: Macros.builtins(),
            wrapListExps: true,
            loadedFiles: new Map<String, Bool>(),
            // Helpful built-in aliases
            callAliases: [
                "print" => Symbol("Prelude.print"),
                "sort" => Symbol("Prelude.sort"),
                "groups" => Symbol("Prelude.groups"),
                "zip" => Symbol("Prelude.zip"),
                "pairs" => Symbol("Prelude.pairs"), // TODO test pairs
                "memoize" => Symbol("Prelude.memoize"), // TODO test memoize
                "map" => Symbol("Lambda.map"),
                "filter" => Symbol("Lambda.filter"), // TODO use truthy as the default filter function
                "has" => Symbol("Lambda.has"),
                "count" => Symbol("Lambda.count")
            ],
            identAliases: new Map(),
            fields: [],
            loadingDirectory: "",
            hscript: false
        };

        // Helpful aliases
        return k;
    }

    static function _try<T>(operation:() -> T):Null<T> {
        try {
            return operation();
        } catch (err:StreamError) {
            Sys.stderr().writeString(err + "\n");
            Sys.exit(1);
            return null;
        } catch (err:CompileError) {
            Sys.stderr().writeString(err + "\n");
            Sys.exit(1);
            return null;
        } catch (err:UnmatchedBracketSignal) {
            Sys.stderr().writeString(Stream.toPrint(err.position) + ': Unmatched ${err.type}\n');
            Sys.exit(1);
            return null;
        } catch (err:Exception) {
            Sys.stderr().writeString("Error: " + err.message + "\n");
            Sys.stderr().writeString(err.stack.toString() + "\n");
            Sys.exit(1);
            return null;
        }
    }

    /**
        Build macro: add fields to a class from a corresponding .kiss file
    **/
    public static function build(?kissFile:String, ?k:KissState, useClassFields = true):Array<Field> {
        var classPath = Context.getPosInfos(Context.currentPos()).file;
        // (load... ) relative to the original file
        var loadingDirectory = Path.directory(classPath);
        if (kissFile == null) {
            kissFile = classPath.withoutDirectory().withoutExtension().withExtension("kiss");
        }

        return _try(() -> {
            if (k == null)
                k = defaultKissState();

            if (useClassFields)
                k.fields = Context.getBuildFields();
            k.loadingDirectory = loadingDirectory;

            load(kissFile, k);

            k.fields;
        });
    }

    public static function load(kissFile:String, k:KissState) {
        k.loadedFiles[kissFile] = true;
        var stream = Stream.fromFile(Path.join([k.loadingDirectory, kissFile]));
        Reader.readAndProcess(stream, k, (nextExp) -> {
            #if test
            Sys.println(nextExp.def.toString());
            #end

            var expr = readerExpToHaxeExpr(nextExp, k);

            // if non-null, stuff it in main()
        });
    }

    /**
     * Build macro: add fields to a Haxe class by compiling multiple Kiss files in order with the same KissState
     */
    public static function buildAll(kissFiles:Array<String>, ?k:KissState, useClassFields = true):Array<Field> {
        if (k == null)
            k = defaultKissState();

        if (useClassFields)
            k.fields = Context.getBuildFields();

        for (file in kissFiles) {
            build(file, k, false);
        }

        return k.fields;
    }

    public static function readerExpToHaxeExpr(exp:ReaderExp, k:KissState):Null<Expr> {
        var macros = k.macros;
        var fieldForms = k.fieldForms;
        var specialForms = k.specialForms;
        // Bind the table arguments of this function for easy recursive calling/passing
        var convert = readerExpToHaxeExpr.bind(_, k);

        if (k.hscript)
            exp = Helpers.removeTypeAnnotations(exp);

        var expr = switch (exp.def) {
            case Symbol(alias) if (k.identAliases.exists(alias)):
                readerExpToHaxeExpr(k.identAliases[alias].withPosOf(exp), k);
            case Symbol(name):
                try {
                    Context.parse(name, exp.macroPos());
                } catch (err:haxe.Exception) {
                    throw CompileError.fromExp(exp, "invalid symbol");
                };
            case StrExp(s):
                EConst(CString(s)).withMacroPosOf(exp);
            case CallExp({pos: _, def: Symbol(ff)}, args) if (fieldForms.exists(ff)):
                k.fields.push(fieldForms[ff](exp, args, k));
                null; // Field forms are no-ops
            case CallExp({pos: _, def: Symbol(mac)}, args) if (macros.exists(mac)):
                var expanded = macros[mac](exp, args, k);
                if (expanded != null) {
                    convert(expanded);
                } else {
                    null;
                };
            case CallExp({pos: _, def: Symbol(specialForm)}, args) if (specialForms.exists(specialForm)):
                specialForms[specialForm](exp, args, k);
            case CallExp({pos: _, def: Symbol(alias)}, args) if (k.callAliases.exists(alias)):
                convert(CallExp(k.callAliases[alias].withPosOf(exp), args).withPosOf(exp));
            case CallExp(func, args):
                ECall(convert(func), [for (argExp in args) convert(argExp)]).withMacroPosOf(exp);
            case ListExp(elements):
                var isMap = false;
                var arrayDecl = EArrayDecl([
                    for (elementExp in elements) {
                        switch (elementExp.def) {
                            case KeyValueExp(_, _):
                                isMap = true;
                            default:
                        }
                        convert(elementExp);
                    }
                ]).withMacroPosOf(exp);
                if (!isMap && k.wrapListExps) {
                    ENew({
                        pack: ["kiss"],
                        name: "List"
                    }, [arrayDecl]).withMacroPosOf(exp);
                } else {
                    arrayDecl;
                };
            case RawHaxe(code):
                Context.parse(code, exp.macroPos());
            case FieldExp(field, innerExp):
                EField(convert(innerExp), field).withMacroPosOf(exp);
            case KeyValueExp(keyExp, valueExp):
                EBinop(OpArrow, convert(keyExp), convert(valueExp)).withMacroPosOf(exp);
            case Quasiquote(innerExp):
                // This statement actually turns into an HScript expression before running
                macro {
                    Helpers.evalUnquotes($v{innerExp}, k, args).def;
                };
            default:
                throw CompileError.fromExp(exp, 'conversion not implemented');
        };
        #if test
        // Sys.println(expr.toString()); // For very fine-grained codegen inspection--slows compilation a lot.
        #end

        return expr;
    }

    public static function forCaseParsing(k:KissState):KissState {
        var copy = new Cloner().clone(k);
        copy.wrapListExps = false;
        copy.macros.remove("or");
        copy.specialForms["or"] = SpecialForms.caseOr;
        return copy;
    }

    public static function convert(k:KissState, exp:ReaderExp) {
        return readerExpToHaxeExpr(exp, k);
    }
}
#end
