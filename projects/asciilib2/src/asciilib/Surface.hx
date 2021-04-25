package asciilib;

import asciilib.Colors;

typedef Letter = {
    char:String,
    color:Color
};

@:build(kiss.Kiss.build())
class Surface {}
