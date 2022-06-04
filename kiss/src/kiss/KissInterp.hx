package kiss;

import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
import kiss.Prelude;

using  hscript.Tools;

/**
 * Specialized hscript interpreter for hscript generated from Kiss expressions.
 * When macrotest is defined by the compiler, many functions run without
 * try/catch statements that are required for correct behavior -- this
 * is actually helpful sometimes because it preserves callstacks from errors in
 * macro definitions.
 */
class KissInterp extends Interp {
    var nullForUnknownVar:Bool;
    var parser = new Parser();

    // TODO standardize this with KissConfig.prepareInterp
    public function new(nullForUnknownVar = false) {
        super();

        this.nullForUnknownVar = nullForUnknownVar;

        variables.set("Reflect", Reflect);
        variables.set("Prelude", Prelude);
        variables.set("Lambda", Lambda);
        variables.set("Std", Std);
        variables.set("Keep", ExtraElementHandling.Keep);
        variables.set("Drop", ExtraElementHandling.Drop);
        variables.set("Throw", ExtraElementHandling.Throw);
        variables.set("Math", Math);
        variables.set("Json", haxe.Json);
        variables.set("StringTools", StringTools);
        variables.set("Path", haxe.io.Path);
        #if (sys || hxnodejs)
        variables.set("Sys", Sys);
        variables.set("FileSystem", sys.FileSystem);
        variables.set("File", sys.io.File);
        #end
        #if sys
        variables.set("Http", sys.Http);
        #end

        #if macro
        variables.set("KissError", kiss.KissError);
        #end

        // Might eventually need to simulate types in the namespace:
        variables.set("kiss", {});
    }

    public var cacheConvertedHScript = false;

    public function evalKiss(kissStr:String):Dynamic {
        #if !(sys || hxnodejs)
        if (cacheConvertedHScript) {
            throw "Cannot used cacheConvertedHScript on a non-sys target";
        }
        #end

        var convert =
            #if (sys || hxnodejs)
            if (cacheConvertedHScript) {
                Prelude.cachedConvertToHScript;
            } else
            #end
                Prelude.convertToHScript;
        return evalHaxe(convert(kissStr));
    }

    public function evalHaxe(hscriptStr:String):Dynamic {
        return execute(parser.parseString(hscriptStr));
    }

    // In some contexts, undefined variables should just return "null" as a falsy value
    override function resolve(id:String):Dynamic {
        if (nullForUnknownVar) {
            return try {
                super.resolve(id);
            } catch (e:Dynamic) {
                null;
            }
        } else {
            return super.resolve(id);
        }
    }

    override function exprReturn(e):Dynamic {
        // the default exprReturn() contains a try-catch which, though it is important (break, continue, and return statements require it), hides very important macroexpansion callstacks sometimes
        #if macrotest
        return expr(e);
        #else
        return super.exprReturn(e);
        #end
    }

    #if macrotest
    override function forLoop(n, it, e) {
        var old = declared.length;
        declared.push({n: n, old: locals.get(n)});
        var it = makeIterator(expr(it));
        while (it.hasNext()) {
            locals.set(n, {r: it.next()});
            // try {
            expr(e);
            /*} catch( err : Stop ) {
                switch( err ) {
                case SContinue:
                case SBreak: break;
                case SReturn: throw err;
                }
            }*/
        }
        restore(old);
    }
    #end
    
    public function publicExprReturn(e) {
        return exprReturn(e);
    }

    public function getLocals() {
        return locals;
    }

    public function setLocals(l) {
        locals = l;
    }

}
