package asciilib;

import asciilib.Colors;
import kiss.Stream;
import haxe.ds.Option;

typedef Letter = {
    char:String,
    color:Color
};

@:build(kiss.Kiss.build())
class Surface {}
