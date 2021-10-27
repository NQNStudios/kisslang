package hollywoo_flixel;

import kiss.Prelude;
import kiss.List;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionManager;
import flixel.input.mouse.FlxMouseButton;
import hollywoo.Scene;
import hollywoo.Director;
import hollywoo_flixel.FlxMovie;

@:build(kiss.Kiss.build())
class FlxDirector implements Director<String, FlxStagePosition, FlxStageFacing, FlxScreenPosition, ActorFlxSprite> {}
