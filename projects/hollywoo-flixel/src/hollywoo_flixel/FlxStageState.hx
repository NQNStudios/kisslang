package hollywoo_flixel;

import flixel.FlxState;
import hollywoo.Stage;

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

typedef FlxStage = Stage<FlxSetState, FlxStagePosition, FlxStageFacing, FlxScreenPosition, FlxActorSprite>;

@:build(kiss.Kiss.build())
class FlxStageState extends FlxState {}
