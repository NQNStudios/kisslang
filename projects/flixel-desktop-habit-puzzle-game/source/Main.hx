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
		var habitFile = if (Sys.args().length > 0 && Sys.args()[0].length > 0) {
			 Sys.args()[0];
		} else {
			"habits/default.txt";
		};
		t.setModel(new HabitModel(habitFile));
		t.model.save();
	}
}
