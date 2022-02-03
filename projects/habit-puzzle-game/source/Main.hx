package;

import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, HabitState, 1, 60, 60, true));
		var t:HabitState = cast FlxG.state;
		t.setModel(new HabitModel(Sys.args()[0]));
	}
}
