package ktxt2;

import kiss.Prelude;
import kiss.List;
import kiss.Stream;
import vscode.*;
import js.lib.Promise;
import sys.io.File;
import re_flex.R;

using haxe.io.Path;
using StringTools;

typedef MessageFromEditor = {
    type:String,
    ?text:String,
    ?start:Int,
    ?end:Int,
    ?position:Int,
    ?source:String,
    ?output:String,
    ?outputStart:Int,
    ?outputEnd:Int
};

@:build(kiss.Kiss.build())
class KTxt2EditorProvider {}
