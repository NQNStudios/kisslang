package hollywoo;

import kiss.AsyncEmbeddedScript;
import kiss.Prelude;
import hollywoo.Scene;

/**
 * Model/controller of a Hollywoo film, and main execution script
 */
@:build(kiss.Kiss.build())
class Movie<Set, StagePosition, StageFacing, ScreenPosition, Actor> extends AsyncEmbeddedScript {
    // TODO for some reason this wasn't working when declared in Movie.kiss:
    // Mutable representation of frames in time:
    var scenes:Map<String, Scene<Set, StagePosition, StageFacing, ScreenPosition, Actor>> = [];
}