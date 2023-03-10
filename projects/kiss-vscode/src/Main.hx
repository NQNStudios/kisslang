import vscode.*;
import Sys;
import sys.io.File;
import sys.FileSystem;
import kiss.Prelude;
import haxe.io.Path;
import js.Node;
import js.node.ChildProcess;
import uuid.Uuid;
import re_flex.R;

using haxe.io.Path;
using StringTools;
using uuid.Uuid;

@:build(kiss.Kiss.build())
class Main {
    // TODO support EMeta(s:MetadataEntry, e:Expr) via Kiss so this signature can be moved to Main.kiss
    @:expose("activate")
    static function activate(context:ExtensionContext) {
        _activate(context);
    }
}
