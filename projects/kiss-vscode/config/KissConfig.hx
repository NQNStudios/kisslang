package;

import kiss.Kiss;
import kiss.Prelude;
import vscode.*;
import js.lib.Promise;

typedef Command = (String) -> Void;

@:expose
@:build(kiss.Kiss.buildAll(["KissConfig.kiss", "Config.kiss"]))
class KissConfig {}
