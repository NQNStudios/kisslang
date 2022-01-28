package;

import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, TypingState, 1, 60, 60, true));
		var t:TypingState = cast FlxG.state;
		trace(Sys.args()[0]);
		t.setModel(new DocumentModel(Sys.args()[0]));
	}
}
