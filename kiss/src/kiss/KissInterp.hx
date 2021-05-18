package kiss;

import hscript.Interp;

class KissInterp extends Interp {
    // TODO standardize this with KissConfig.prepareInterp
    function new() {
        super();

        variables.set("Prelude", Prelude);
        variables.set("Lambda", Lambda);
        variables.set("Std", Std);
    }
}
