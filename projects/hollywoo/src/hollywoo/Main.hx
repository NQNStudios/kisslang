package hollywoo;

import kiss.Kiss;
import kiss.Prelude;
import hollywoo.text.TextDirector;
import hollywoo.text.TextStage;
import kiss.EmbeddedScript;

@:build(kiss.EmbeddedScript.build("HollywooDSL.kiss", "examples/pure-hollywoo/basic.hollywoo"))
class BasicHollywoo extends TextStage {}

@:build(kiss.Kiss.build())
class Main {}
