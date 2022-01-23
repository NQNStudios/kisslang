package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.input.gamepad.FlxGamepad;
import flixel.text.FlxText;

using flixel.util.FlxSpriteUtil;

enum ButtonBehavior
{
	Cycle(behaviors:Array<ButtonBehavior>);
	Tab;
	Control;
	Backspace;
	Shift;
	Space;
	Letter(char:String);
}

// In DDR order:
enum ArrowDir
{
	Left;
	Down;
	Up;
	Right;
}

class TypingState extends FlxState
{
	var buttonIDs:Map<Int, String>;
	var buttonBehaviors:Map<String, ButtonBehavior>;

	override public function create()
	{
		super.create();

		// for now, hard-coded for the wii pad only
		buttonIDs = [
			16 => "-", 12 => "+", 7 => "B", 17 => "Up", 6 => "A", 19 => "Left", 20 => "Right", 9 => "Y", 18 => "Down", 8 => "X"
		];

		buttonBehaviors = [
			"-" => Tab,
			"+" => Control,
			"B" => Cycle([
				Letter("m"), Letter("f"), Letter("w"), Letter("y"), Letter("p"), Letter("v"), Letter("b"), Letter("g"), Letter("k"), Letter("j"), Letter("q"),
				Letter("x"), Letter("z")]),
			"A" => Cycle([
				Letter("g"), Letter("k"), Letter("j"), Letter("q"), Letter("x"), Letter("z"), Letter("m"), Letter("f"), Letter("w"), Letter("y"), Letter("p"),
				Letter("v"), Letter("b")]),
			"Left" => Cycle([
				Letter("s"),
				Letter("h"),
				Letter("r"),
				Letter("d"),
				Letter("l"),
				Letter("u"),
				Letter("c"),
			]),
			"Up" => Cycle([Letter("e"), Letter("t"), Letter("a"), Letter("o"), Letter("i"), Letter("n")]),
			"Down" => Cycle([Letter("o"), Letter("i"), Letter("n"), Letter("e"), Letter("t"), Letter("a")]),
			"Y" => Backspace,
			"Right" => Shift,
			"X" => Space
		];

		var background = new FlxSprite();
		background.makeGraphic(1280, 720, FlxColor.BLACK);
		// background.x = 0;
		// background.y = 0;

		FlxSpriteUtil.beginDraw(FlxColor.WHITE);

		var spacing = 20;
		var shapeSize = 100;
		var x = spacing;
		var y = 720 - shapeSize - spacing;

		// Split the screen into text area and dance area:
		var splitX = 1280 / 2 + shapeSize;
		background.drawLine(splitX, 0, splitX, 720);
		// Split the left side into upper/lower:
		background.drawLine(0, 720 - shapeSize - spacing * 2, splitX, 720 - shapeSize - spacing * 2);

		var bSprite = makeCircleSprite("B", x, y);
		x += shapeSize + spacing;
		var leftSprite = makeTriangleSprite(Left, "", x, y);
		x += shapeSize + spacing;
		var downSprite = makeTriangleSprite(Down, "", x, y);
		x += shapeSize + spacing;
		var upSprite = makeTriangleSprite(Up, "", x, y);
		x += shapeSize + spacing;
		var rightSprite = makeTriangleSprite(Right, "", x, y);
		x += shapeSize + spacing;
		var aSprite = makeCircleSprite("A", x, y);

		add(background);
		add(bSprite);
		add(leftSprite);
		add(downSprite);
		add(upSprite);
		add(rightSprite);
		add(aSprite);
	}

	function makeTriangleSprite(dir:ArrowDir, text:String, x:Int, y:Int):FlxSprite
	{
		var spr = new FlxSprite();
		spr.makeGraphic(100, 100, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.beginDraw(FlxColor.WHITE);
		spr.drawTriangle(0, 0, 100);

		spr.angle = switch (dir)
		{
			case Left:
				-90;
			case Down:
				180;
			case Up:
				0;
			case Right:
				90;
		};
		var text = new FlxText(text, 24);
		text.angle = -spr.angle;
		text.color = FlxColor.BLACK;
		spr.stamp(text, 50 - Math.floor(text.width / 2), 50 - Math.floor(text.height / 2));

		spr.x = x;
		spr.y = y;
		return spr;
	}

	function makeCircleSprite(text:String, x:Int, y:Int):FlxSprite
	{
		var spr = new FlxSprite();
		spr.makeGraphic(100, 100, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.beginDraw(FlxColor.WHITE);
		spr.drawCircle();
		var text = new FlxText(text, 24);
		text.color = FlxColor.BLACK;
		spr.stamp(text, 50 - Math.floor(text.width / 2), 50 - Math.floor(text.height / 2));
		spr.x = x;
		spr.y = y;
		return spr;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// Important: can be null if there's no active gamepad yet!
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		if (gamepad != null)
		{
			updateGamepadInput(gamepad);
		}
	}

	function updateGamepadInput(gamepad:FlxGamepad):Void
	{
		var id = gamepad.firstJustPressedRawID();
		if (id != -1)
		{
			var whichButton = buttonIDs[id];
		}
	}
}
