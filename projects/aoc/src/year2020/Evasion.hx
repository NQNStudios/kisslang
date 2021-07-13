package year2020;

import kiss.EmbeddedScript;
import kiss.Prelude;

#if (day12 && year2020)
@:build(kiss.EmbeddedScript.build("EvasionDSL.kiss", "inputs/day12.txt"))
class EvasionScript extends EmbeddedScript {}
#end
