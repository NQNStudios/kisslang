package year2020;

import kiss.EmbeddedScript;
import kiss.Prelude;

@:build(kiss.EmbeddedScript.build("EvasionDSL.kiss", "inputs/day12.txt"))
class EvasionScript extends EmbeddedScript {}
