package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import haxe.ds.Option;
import kiss.Prelude;
import kiss.List;

using flixel.util.FlxSpriteUtil;

// In DDR order:
enum ArrowDir
{
	Left;
	Down;
	Up;
	Right;
}

@:build(kiss.Kiss.build())
class TypingState extends FlxState
{
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

	function getFirstInputId():Option<Int> {
		// Important: can be null if there's no active gamepad yet!
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		if (gamepad != null)
		{
			var firstGamepadId = gamepad.firstJustPressedRawID();
			if (firstGamepadId != -1) {
				return Some(firstGamepadId);
			}
		}

		var firstKeyId = FlxG.keys.firstJustPressed();
		if (firstKeyId != -1) {
			return Some(firstKeyId);
		} else {
			return None;
		}
	}
}
