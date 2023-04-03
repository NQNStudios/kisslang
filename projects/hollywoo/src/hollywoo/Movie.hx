package hollywoo;

import haxe.Constraints.Function;
import haxe.Timer;
import kiss.AsyncEmbeddedScript;
import kiss.Prelude;
import kiss.Stream;
import kiss.FuzzyMap;
import hollywoo.Scene;
import hollywoo.Director;
import hollywoo.StagePosition;
import haxe.Json;
import uuid.Uuid;
import haxe.ds.Option;
import kiss_tools.JsonMap;
import kiss_tools.JsonableArray;
import kiss_tools.TimerWithPause;

using kiss.FuzzyMapTools;

typedef Cloneable<T> = {
    function clone():T;
}

enum DelayHandling {
    Auto;
    AutoWithSkip;
    Manual;
}

typedef VoiceLine = {
    trackKey:String,
    start:Float,
    end:Float,
    ?alts:Array<VoiceLine>
};

enum CreditsLine {
    OneColumn(s:String);
    TwoColumn(left:String, right:String);
    ThreeColumn(left:String, center:String, right:String);
    Break;
}

/**
 * Model/controller of a Hollywoo film, and main execution script
 */
@:build(kiss.Kiss.build())
class Movie<Set:Cloneable<Set>, Actor, Sound, Song, Prop, VoiceTrack, Camera, LightSource:Jsonable<LightSource>> extends AsyncEmbeddedScript {}
