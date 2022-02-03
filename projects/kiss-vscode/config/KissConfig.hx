package;

import kiss.Kiss;
import kiss.Prelude;
import kiss.Stream;
import vscode.*;
import js.lib.Promise;
import js.node.ChildProcess;
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;
import ktxt2.KTxt2;
import re_flex.R;
import kiss_tools.KeyShortcutHandler;

using haxe.io.Path;
using StringTools;

typedef Command = (String) -> Void;

@:expose
@:build(kiss.Kiss.buildAll(["KissConfig.kiss", "Config.kiss"]))
class KissConfig {}
