package;

import kiss.Kiss;
import kiss.Prelude;
import vscode.*;
import js.lib.Promise;
import js.node.ChildProcess;
import js.node.buffer.Buffer;
import hscript.Parser;
import hscript.Interp;

typedef Command = (String) -> Void;

@:expose
@:build(kiss.Kiss.buildAll(["KissConfig.kiss", "Config.kiss"]))
class KissConfig {}
