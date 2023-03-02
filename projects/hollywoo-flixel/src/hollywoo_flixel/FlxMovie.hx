package hollywoo_flixel;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import hollywoo.Director;
import hollywoo.Movie;
import hollywoo_flixel.ActorFlxSprite;
import kiss_flixel.SpriteTools;
import openfl.Assets;

/*
enum FlxStagePosition {
    Left;
    Right;
    LeftBehind;
    RightBehind;

    // Specify the layer and position relative to screen size, or in absolute coordinates, etc.
    // AND don't move the object automatically for any reason
    FullControl(layer:Int, pos:RelativePosition);
}
*/

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
class FlxMovie extends Movie<FlxSprite, FlxScreenPosition, ActorFlxSprite, FlxSound, String, FlxSprite, FlxSound> {
    // Think of HollywooFlixelDSL.kiss as the corresponding Kiss file for this class!

    public function new(director:FlxDirector, ?voiceLinesAssetPath:String) {
        var voiceLinesJson = null;
        if (voiceLinesAssetPath != null) {
            voiceLinesJson = Assets.getText(voiceLinesAssetPath);
        }

        super(director, voiceLinesJson);

        stagePositions["Left"] = {
            x: FlxDirector.STAGE_LEFT_X,
            y: FlxDirector.ACTOR_Y,
            z: 0.0
        };
        stagePositions["Right"] = {
            x: FlxDirector.STAGE_RIGHT_X,
            y: FlxDirector.ACTOR_Y,
            z: 0.0
        };
        stagePositions["Left2"] = {
            x: FlxDirector.STAGE_LEFT_X,
            y: FlxDirector.ACTOR_Y,
            z: FlxDirector.STAGE_BEHIND_DY
        };
        stagePositions["Right2"] = {
            x: FlxDirector.STAGE_RIGHT_X,
            y: FlxDirector.ACTOR_Y,
            z: FlxDirector.STAGE_BEHIND_DY
        };
    }
}
