package hollywoo_flixel;

import kiss.Prelude;
import kiss.List;
import hollywoo.Director;
import hollywoo.Stage;

import hollywoo_flixel.FlxStageState;

@:build(kiss.Kiss.build())
class FlxDirector implements Director<FlxSetState, FlxStagePosition, FlxStageFacing, FlxScreenPosition, FlxActorSprite> {}
