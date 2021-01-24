package;

import kiss.Kiss;
import kiss.Prelude;
import js.lib.Promise;

typedef Command = (?String) -> Void;

@:build(kiss.Kiss.buildAll(["KissConfig.kiss", "Config.kiss"]))
class KissConfig {}
