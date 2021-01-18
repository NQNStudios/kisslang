package;

import kiss.Kiss;
import kiss.Prelude;
import js.lib.Promise;

typedef Command = (?String) -> Void;

@:build(kiss.Kiss.build("Config.kiss"))
@:build(kiss.Kiss.build("KissConfig.kiss"))
class KissConfig {}
