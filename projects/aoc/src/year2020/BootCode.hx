package year2020;

import kiss.EmbeddedScript;
import kiss.Prelude;

@:build(kiss.EmbeddedScript.build("src/year2020/BootCodeDSL.kiss", "src/year2020/inputs/day8-example.txt"))
class BootCodeExample extends EmbeddedScript {}

@:build(kiss.EmbeddedScript.build("src/year2020/BootCodeDSL.kiss", "src/year2020/inputs/day8.txt"))
class BootCodeReal extends EmbeddedScript {}

@:build(kiss.EmbeddedScript.build("src/year2020/BootCodeFixDSL.kiss", "src/year2020/inputs/day8-example.txt"))
class BootCodeFixExample extends EmbeddedScript {}

@:build(kiss.EmbeddedScript.build("src/year2020/BootCodeFixDSL.kiss", "src/year2020/inputs/day8.txt"))
class BootCodeFix extends EmbeddedScript {}
