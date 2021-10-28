package kiss;

import hscript.Parser;
import hscript.Interp;
import kiss.Prelude;

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

        parser.allowTypes = true;

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
        #if (sys || hxnodejs)
        variables.set("Sys", Sys);
        #end
        #if sys
        variables.set("Http", sys.Http);
        #end

        // Might eventually need to simulate types in the namespace:
        variables.set("kiss", {});
    }

    public function evalKiss(kissStr:String):Dynamic {
        return evalHaxe(Prelude.convertToHScript(kissStr));
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
        // the default exprReturn() contains a try-catch which, though it is important, hides very important macroexpansion callstacks sometimes
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
}
