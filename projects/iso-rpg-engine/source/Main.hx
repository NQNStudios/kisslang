package;

import flixel.FlxGame;
import openfl.display.Sprite;
import data.blades.ScenData;

class Main extends Sprite
{
	public function new()
	{
		var scenData = new ScenData();
		scenData.load("Data/corescendata.txt");
		scenData.load("Data/corescendata2.txt");
		
		scenData.test();


		super();
		addChild(new FlxGame(0, 0, IsometricMapState));
	}
}
