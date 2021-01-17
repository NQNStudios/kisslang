import vscode.*;
import Sys;
import sys.io.Process;
import kiss.Kiss;
import kiss.Prelude;
import haxe.io.Path;

@:build(kiss.Kiss.build("src/Main.kiss"))
class Main {
    // TODO support EMeta(s:MetadataEntry, e:Expr) via Kiss
    @:expose("activate")
    static function activate(context:ExtensionContext) {
        _activate(context);
    }
}
