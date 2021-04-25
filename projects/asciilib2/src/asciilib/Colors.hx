package asciilib;

import haxe.io.Bytes;

typedef Color = {
    r:Int,
    g:Int,
    b:Int,
}

/**
 * The Colors class represents a 2D grid of colors. Under the hood, it's byte channels
 */
@:build(kiss.Kiss.build())
class Colors {}
