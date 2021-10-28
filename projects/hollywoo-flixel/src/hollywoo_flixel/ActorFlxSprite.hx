package hollywoo_flixel;

import kiss.Prelude;
import kiss.List;
import flixel.FlxSprite;

typedef AnimationArgs = {
    name:String,
    frames:Array<Int>,
    ?frameRate:Float, // default 30
    ?looped:Bool, // default true
    ?flipX:Bool, // default false
    ?flipY:Bool // default false
};

@:build(kiss.Kiss.build())
class ActorFlxSprite extends FlxSprite {}
