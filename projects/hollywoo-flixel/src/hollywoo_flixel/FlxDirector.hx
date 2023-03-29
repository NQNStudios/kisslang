package hollywoo_flixel;

import kiss.Prelude;
import kiss.List;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionManager;
import flixel.input.mouse.FlxMouseButton;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import hollywoo.Movie;
import hollywoo.Scene;
import hollywoo.Director;
import hollywoo_flixel.FlxMovie;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.system.FlxSound;
import flixel.FlxCamera;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import haxe.Constraints;
import kiss_flixel.SpriteTools;
import haxe.ds.Option;
using flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;
import openfl.display.BitmapDataChannel;
import openfl.geom.Rectangle;
import openfl.geom.Point;

@:build(kiss.Kiss.build())
class FlxDirector implements Director<FlxSprite, FlxScreenPosition, ActorFlxSprite, FlxSound, String, FlxSprite, FlxSound, FlxCamera, FlxLightSource> {
    public static function blackAlphaMaskFlxSprite(sprite:FlxSprite, mask:FlxSprite, output:FlxSprite):FlxSprite
    {
        sprite.drawFrame();
        var data:BitmapData = sprite.pixels.clone();
        data.copyChannel(mask.pixels, new Rectangle(0, 0, sprite.width, sprite.height), new Point(), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
        output.pixels = data;
        return output;
 }

}
