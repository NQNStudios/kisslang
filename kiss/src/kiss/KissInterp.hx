package kiss;

import hscript.Interp;
import kiss.Prelude;

class KissInterp extends Interp {
    // TODO standardize this with KissConfig.prepareInterp
    public function new() {
        super();

        variables.set("Prelude", Prelude);
        variables.set("Lambda", Lambda);
        variables.set("Std", Std);
        variables.set("Keep", ExtraElementHandling.Keep);
        variables.set("Drop", ExtraElementHandling.Drop);
        variables.set("Throw", ExtraElementHandling.Throw);
    }

    override function exprReturn(e):Dynamic {
        // the default exprReturn() contains a try-catch which, though it is important, hides very important macroexpansion callstacks sometimes
        #if macrotest
        return expr(e);
        #else
        return super.exprReturn(e);
        #end
    }
}
