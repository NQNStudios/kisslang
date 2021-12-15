package hollywoo;

import haxe.Constraints.Function;
import haxe.Timer;
import kiss.AsyncEmbeddedScript;
import kiss.Prelude;
import kiss.FuzzyMap;
import hollywoo.Scene;
import hollywoo.Director;

enum DelayHandling {
    Auto;
    AutoWithSkip;
    Manual;
}

/**
 * Model/controller of a Hollywoo film, and main execution script
 */
@:build(kiss.Kiss.build())
class Movie<Set, StagePosition, StageFacing, ScreenPosition, Actor, Sound, Song, Prop> extends AsyncEmbeddedScript {
    // TODO for some reason this wasn't working when declared in Movie.kiss:
    // Mutable representation of frames in time:
    var scenes:FuzzyMap<Scene<Set, StagePosition, StageFacing, ScreenPosition, Actor, Prop>> = new FuzzyMap<Scene<Set, StagePosition, StageFacing, ScreenPosition, Actor, Prop>>();
}
