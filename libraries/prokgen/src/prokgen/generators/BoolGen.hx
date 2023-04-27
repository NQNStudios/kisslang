package prokgen.generators;

import prokgen.ProkRandom;

class BoolGen implements Generator<Bool> {
    var r:ProkRandom;

    public function new() {}
    
    public function use(r:ProkRandom) {
        this.r = r;
    }

    public function makeRandom() {
        return r.bool();
    }

    public function combine(a:Bool, b:Bool) {
        return r.getObject([a, b]);
    }
}
