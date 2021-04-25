package year2020;

import kiss.EmbeddedScript;
import kiss.Prelude;

@:build(kiss.EmbeddedScript.build("BootCodeDSL.kiss", "inputs/day8-example.txt"))
class BootCodeExample extends EmbeddedScript {}

@:build(kiss.EmbeddedScript.build("BootCodeDSL.kiss", "inputs/day8.txt"))
class BootCodeReal extends EmbeddedScript {}

@:build(kiss.EmbeddedScript.build("BootCodeFixDSL.kiss", "inputs/day8-example.txt"))
class BootCodeFixExample extends EmbeddedScript {}

@:build(kiss.EmbeddedScript.build("BootCodeFixDSL.kiss", "inputs/day8.txt"))
class BootCodeFix extends EmbeddedScript {}
