package prokgen.examples;

import prokgen.generators.*;

@:build(prokgen.Generable.build())
class HighNumbers {
    var i:Int;
    var f:Float;
    var iList:Array<Int>;
    var fList:Array<Float>;

    static var iGen = new IntGen(-1000, 1000);
    static var fGen = new FloatGen(-1000, 100);
    static var iListGen = new ArrayGen<Int>(new IntGen(-1000, 1000), 0, 10);
    static var fListGen = new ArrayGen<Float>(new FloatGen(-1000, 1000), 0, 10);

    function toString() {
        return '$i $f $iList $fList';
    }

    function genScore() {
        var sum:Float = i + f;
        for (i in iList) {
            sum += i;
        }
        for (f in fList) {
            sum += f;
        }
        return sum;
    }

}
