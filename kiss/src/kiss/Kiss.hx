package kiss;

#if macro
import haxe.Exception;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.io.Path;
import kiss.Stream;
import kiss.Reader;
import kiss.FieldForms;
import kiss.SpecialForms;
import kiss.Macros;
import kiss.CompileError;
import kiss.cloner.Cloner;

using kiss.Helpers;
using kiss.Reader;
using tink.MacroApi;

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
    identAliases:Map<String, ReaderExpDef>
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
            identAliases: new Map()
        };

        // Helpful aliases
        return k;
    }

    static function _try<T>(operation:() -> T):Null<T> {
        try {
            return operation();
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
    public static function build(kissFile:String, ?k:KissState, useClassFields = true):Array<Field> {
        return _try(() -> {
            var classFields:Array<Field> = if (useClassFields) Context.getBuildFields() else [];
            var stream = new Stream(kissFile);

            // (load... ) relative to the original file
            var loadingDirectory = Path.directory(kissFile);

            if (k == null)
                k = defaultKissState();

            Reader.readAndProcess(stream, k, (nextExp) -> {
                #if test
                Sys.println(nextExp.def.toString());
                #end
                switch (nextExp.def) {
                    // (load... ) is the specialest of forms because it calls build() again and those fields need to be merged
                    case CallExp({pos: _, def: Symbol("load")}, loadArgs):
                        nextExp.checkNumArgs(1, 1, "(load \"[file]\")");
                        switch (loadArgs[0].def) {
                            case StrExp(otherKissFile):
                                var filePath = Path.join([loadingDirectory, otherKissFile]);
                                if (!k.loadedFiles.exists(filePath)) {
                                    var loadedFields = Kiss.build(filePath, k, false);
                                    for (field in loadedFields) {
                                        classFields.push(field);
                                    }
                                    k.loadedFiles[filePath] = true;
                                }
                            default:
                                throw CompileError.fromExp(loadArgs[0], "only argument to load should be a string literal");
                        }
                    default:
                        var field = readerExpToField(nextExp, k);
                        if (field != null) {
                            #if test
                            switch (field.kind) {
                                case FVar(_, expr) | FFun({ret: _, args: _, expr: expr}):
                                    Sys.println(expr.toString());
                                default:
                                    throw CompileError.fromExp(nextExp, 'cannot print the expression of generated field $field');
                            }
                            #end
                            classFields.push(field);
                        }
                }
            });

            classFields;
        });
    }

    /**
     * Build macro: add fields to a Haxe class by compiling multiple Kiss files in order with the same KissState
     */
    public static function buildAll(kissFiles:Array<String>, ?k:KissState, useClassFields = true):Array<Field> {
        if (k == null)
            k = defaultKissState();

        var fields = [];

        for (file in kissFiles) {
            fields = fields.concat(build(file, k, useClassFields));
        }

        return fields;
    }

    public static function readerExpToField(exp:ReaderExp, k:KissState, errorIfNot = true):Null<Field> {
        var fieldForms = k.fieldForms;

        // Macros at top-level are allowed if they expand into a fieldform, or null like defreadermacro
        var macros = k.macros;
        var callAliases = k.callAliases;
        var identAliases = k.identAliases;

        return switch (exp.def) {
            case CallExp({pos: _, def: Symbol(mac)}, args) if (macros.exists(mac)):
                var expandedExp = macros[mac](exp, args, k);
                if (expandedExp != null) readerExpToField(expandedExp, k, errorIfNot) else null;
            case CallExp({pos: _, def: Symbol(alias)}, args) if (callAliases.exists(alias)):
                var aliasedExp = CallExp(callAliases[alias].withPosOf(exp), args).withPosOf(exp);
                readerExpToField(aliasedExp, k, errorIfNot);
            case CallExp({pos: _, def: Symbol(alias)}, args) if (identAliases.exists(alias)):
                var aliasedExp = CallExp(identAliases[alias].withPosOf(exp), args).withPosOf(exp);
                readerExpToField(aliasedExp, k, errorIfNot);
            case CallExp({pos: _, def: Symbol(formName)}, args) if (fieldForms.exists(formName)):
                fieldForms[formName](exp, args, k);
            default:
                if (errorIfNot) throw CompileError.fromExp(exp, 'invalid valid field form'); else return null;
        };
    }

    public static function readerExpToHaxeExpr(exp:ReaderExp, k:KissState):Expr {
        var macros = k.macros;
        var specialForms = k.specialForms;
        // Bind the table arguments of this function for easy recursive calling/passing
        var convert = readerExpToHaxeExpr.bind(_, k);
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
            case CallExp({pos: _, def: Symbol(mac)}, args) if (macros.exists(mac)):
                convert(macros[mac](exp, args, k));
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
