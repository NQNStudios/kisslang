package hollywoo_flixel;

import flixel.FlxState;
import flixel.FlxSprite;
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

class FlxMovie extends Movie<String, FlxStagePosition, FlxStageFacing, FlxScreenPosition, ActorFlxSprite> {}
