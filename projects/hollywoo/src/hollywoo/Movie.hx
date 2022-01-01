package hollywoo;

import haxe.Constraints.Function;
import haxe.Timer;
import kiss.AsyncEmbeddedScript;
import kiss.Prelude;
import kiss.Stream;
import kiss.FuzzyMap;
import hollywoo.Scene;
import hollywoo.Director;
import haxe.Json;
import uuid.Uuid;

using kiss.FuzzyMapTools;

enum DelayHandling {
    Auto;
    AutoWithSkip;
    Manual;
}

typedef VoiceLine = {
    trackKey:String,
    start:Float,
    end:Float
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
class Movie<Set, StagePosition, StageFacing, ScreenPosition, Actor, Sound, Song, Prop, VoiceTrack> extends AsyncEmbeddedScript {
    // TODO for some reason this wasn't working when declared in Movie.kiss:
    // Mutable representation of frames in time:
    var scenes:FuzzyMap<Scene<Set, StagePosition, StageFacing, ScreenPosition, Actor, Prop>> = new FuzzyMap<Scene<Set, StagePosition, StageFacing, ScreenPosition, Actor, Prop>>();
}
