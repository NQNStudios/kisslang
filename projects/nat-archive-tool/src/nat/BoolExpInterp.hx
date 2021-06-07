package nat;

import kiss.KissInterp;
import hscript.Parser;
import kiss.Prelude;

@:build(kiss.Kiss.build())
class BoolExpInterp extends KissInterp {
    public function new() {
        super();
    }

    override function resolve(id:String):Dynamic {
        return try {
            super.resolve(id);
        } catch (e:Dynamic) {
            false;
        }
    }
}
