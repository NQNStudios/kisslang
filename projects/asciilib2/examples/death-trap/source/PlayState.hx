package;

import flixel.FlxState;
import asciilib.Game;
import asciilib.backends.flixel.*;

class PlayState extends FlxState
{
	var game:Game;

	override public function create()
	{
		super.create();
		game = new Game("Beware Yon Death Trap", 40, 24, 8, 12, new DeathTrapLogic(), new FlxGraphicsBackend(this));
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		game.update(elapsed);
		game.draw();
	}
}
