package nap;

import kiss.KissInterp;

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
