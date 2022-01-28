package;

import kiss.Prelude;
import kiss.List;
import sys.io.File;
import sys.FileSystem;
import flixel.math.FlxRandom;
import haxe.io.Path;

typedef ArrowStuff = {
    text:String,
    action:Void->Void
};

@:build(kiss.Kiss.build())
class DocumentModel {}
