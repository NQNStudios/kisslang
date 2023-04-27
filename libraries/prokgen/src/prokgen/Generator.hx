package prokgen;

interface Generator<T> {
    function use(s:ProkRandom):Void;
    function makeRandom():T;
    function combine(a:T, b:T):T;
}
