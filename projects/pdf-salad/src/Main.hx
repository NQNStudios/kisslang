package;

import haxe.Constraints;
import js.lib.Uint8Array;
import js.node.Fs;
import js.lib.Promise;
import kiss.Kiss;
import kiss.Prelude;
import Externs;

@:build(kiss.Kiss.build("src/Main.kiss"))
class Main {}
