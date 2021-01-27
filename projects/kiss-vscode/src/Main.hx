import vscode.*;
import Sys;
import sys.io.File;
import sys.FileSystem;
import kiss.Prelude;
import haxe.io.Path;
import js.Node;
import js.node.ChildProcess;
import uuid.Uuid;

using StringTools;
using uuid.Uuid;

typedef Command = (String) -> Void;

typedef KissConfig = {
    registerBuiltins:() -> Void,
    registerCommand:(String, Command) -> Void,
    runCommand:() -> Void,
    init:() -> Void
};

@:build(kiss.Kiss.build("src/Main.kiss"))
class Main {
    // TODO support EMeta(s:MetadataEntry, e:Expr) via Kiss so this signature can be moved to Main.kiss
    @:expose("activate")
    static function activate(context:ExtensionContext) {
        _activate(context);
    }
}
