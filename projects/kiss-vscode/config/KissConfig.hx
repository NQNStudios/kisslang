package;

import kiss.Kiss;
import kiss.Prelude;
import kiss.Operand;
import kiss.Stream;
import vscode.*;
import js.lib.Promise;
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;

typedef Command = (String) -> Void;

enum ShortcutKey {
    Final(command:String);
    Prefix(keys:Map<String, ShortcutKey>);
}

@:expose
@:build(kiss.Kiss.buildAll(["KissConfig.kiss", "Config.kiss"]))
class KissConfig {}
