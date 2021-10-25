package ktxt2;

import kiss.Stream;
import kiss.Prelude;
import kiss.KissInterp;

using haxe.io.Path;
using StringTools;

typedef KTxt2Block = {
    source:String,
    output:String,
    outputLocked:Bool,
    // kiss.Stream.Positions:
    sourceStart:Position,
    sourceEnd:Position,
    outputStart:Position,
    outputEnd:Position
};

typedef KTxt2Comment = {
    text:String,
    start:Position,
    end:Position
};

enum KTxt2Element {
    Comment(comment:KTxt2Comment);
    Block(block:KTxt2Block);
}

typedef KTxt2Conversion = {
    sourceType:String,
    outputType:String,
    canConvert:String->Bool,
    convert:String->String,
    name:String
};

@:build(kiss.Kiss.build())
class KTxt2 {}
