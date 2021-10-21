package ktxt2;

import kiss.Stream;
import kiss.Prelude;

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

enum KTxt2Element {
    Comment(content:String);
    Block(block:KTxt2Block);
}

@:build(kiss.Kiss.build())
class KTxt2 {}
