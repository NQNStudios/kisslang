package hollywoo_flixel;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import hollywoo.Movie;
import hollywoo_flixel.ActorFlxSprite;
import hollywoo_flixel.SceneFlxState;
import hollywoo_flixel.SpriteTools;
import openfl.Assets;

enum FlxStagePosition {
    Left;
    Right;
    LeftBehind;
    RightBehind;
}

enum FlxStageFacing {
    Left;
    Right;
}

enum FlxScreenPosition {
    // Shortcuts
    UpperLeft;
    UpperRight;
    LowerLeft;
    LowerRight;
    LowerCenter;
    UpperCenter;
    Center;

    // Specify the layer and position relative to screen size, or in absolute coordinates, etc.
    FullControl(layer:Int, pos:RelativePosition);
}

/**
 * Model/controller of a Hollywoo-Flixel film, and main execution script
 */
class FlxMovie extends Movie<String, FlxStagePosition, FlxStageFacing, FlxScreenPosition, ActorFlxSprite, FlxSound, String, FlxSprite, FlxSound> {
    // Think of HollywooFlixelDSL.kiss as the corresponding Kiss file for this class!

    public function new(director:FlxDirector, ?voiceLinesAssetPath:String) {
        var voiceLinesJson = null;
        if (voiceLinesAssetPath != null) {
            voiceLinesJson = Assets.getText(voiceLinesAssetPath);
        }
        super(director, voiceLinesJson);
    }
}
