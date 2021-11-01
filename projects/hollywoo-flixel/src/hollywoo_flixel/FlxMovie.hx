package hollywoo_flixel;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import hollywoo.Movie;
import hollywoo_flixel.ActorFlxSprite;
import hollywoo_flixel.SceneFlxState;

enum FlxStagePosition {
    Left;
    Right;
}

enum FlxStageFacing {
    Left;
    Right;
}

enum FlxScreenPosition {
    UpperLeft;
    UpperRight;
    LowerLeft;
    LowerRight;
    LowerCenter;
    UpperCenter;
}

/**
 * Model/controller of a Hollywoo-Flixel film, and main execution script
 */
class FlxMovie extends Movie<String, FlxStagePosition, FlxStageFacing, FlxScreenPosition, ActorFlxSprite, FlxSound> {}
