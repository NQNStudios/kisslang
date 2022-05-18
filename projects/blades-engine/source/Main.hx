package;

import flixel.FlxGame;
import openfl.display.Sprite;
import data.ScenData;

class Main extends Sprite
{
	public function new()
	{
		var scenData = new ScenData();
		scenData.load("Data/corescendata.txt");
		super();
		// addChild(new FlxGame(0, 0, IsometricMapState));
	}
}
