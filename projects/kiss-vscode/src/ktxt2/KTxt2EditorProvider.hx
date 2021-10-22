package ktxt2;

import kiss.Prelude;
import kiss.List;
import vscode.*;
import js.lib.Promise;

typedef MessageFromEditor = {
    type:String,
    ?text:String,
    ?start:kiss.Stream.Position,
    ?end:kiss.Stream.Position,
    ?position:kiss.Stream.Position,
    ?source:String,
    ?output:String,
    ?outputStart:kiss.Stream.Position,
    ?outputEnd:kiss.Stream.Position
};

@:build(kiss.Kiss.build())
class KTxt2EditorProvider {}
