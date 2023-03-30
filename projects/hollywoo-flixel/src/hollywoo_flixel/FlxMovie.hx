package hollywoo_flixel;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import hollywoo.Director;
import hollywoo.Movie;
import hollywoo_flixel.ActorFlxSprite;
import kiss_flixel.SpriteTools;
import openfl.Assets;

/**
 * Model/controller of a Hollywoo-Flixel film, and main execution script
 */
class FlxMovie extends Movie<FlxSprite, ActorFlxSprite, FlxSound, String, FlxSprite, FlxSound, FlxCamera, FlxLightSource> {
    // Think of HollywooFlixelDSL.kiss as the corresponding Kiss file for this class!

    public function new(director:FlxDirector, lightSourceJsonFile:String, positionsJson:String, ?voiceLinesAssetPath:String) {
        var voiceLinesJson = null;
        if (voiceLinesAssetPath != null) {
            voiceLinesJson = Assets.getText(voiceLinesAssetPath);
        }

        super(director, lightSourceJsonFile, new FlxLightSource([], FlxColor.TRANSPARENT), positionsJson, voiceLinesJson);
    }
    public var uiCamera:FlxCamera;
    public var screenCamera:FlxCamera;

    public var STAGE_LEFT_X:Float;
    public var STAGE_RIGHT_X:Float;
    public var ACTOR_WIDTH:Int;
    public var STAGE_BEHIND_DY:Float;
    public var ACTOR_Y:Float;
    public var DIALOG_X:Float;
    public var DIALOG_Y:Float;
    public var DIALOG_WIDTH:Int;
    public var DIALOG_HEIGHT:Int;
}
