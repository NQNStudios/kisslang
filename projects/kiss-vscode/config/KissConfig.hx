package;

import kiss.Kiss;
import kiss.Prelude;
import kiss.Stream;
import vscode.*;
import js.lib.Promise;
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
import haxe.io.Path;
import sys.io.File;

using haxe.io.Path;

typedef Command = (String) -> Void;

enum ShortcutKey {
    Final(command:String);
    Prefix(keys:Map<String, ShortcutKey>);
}

@:expose
@:build(kiss.Kiss.buildAll(["KissConfig.kiss", "Config.kiss"]))
class KissConfig {}
