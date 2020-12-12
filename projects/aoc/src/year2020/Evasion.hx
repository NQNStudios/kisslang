package year2020;

import kiss.EmbeddedScript;
import kiss.Prelude;

@:build(kiss.EmbeddedScript.build("src/year2020/EvasionDSL.kiss", "src/year2020/inputs/day12.txt"))
class EvasionScript extends EmbeddedScript {}
