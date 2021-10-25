package hollywoo;

import kiss.AsyncEmbeddedScript;

/**
 * Model of a Hollywoo film
 */
@:build(kiss.Kiss.build())
class Movie<Set, StagePosition, StageFacing, ScreenPosition, Actor> extends AsyncEmbeddedScript {
    // TODO for some reason this wasn't working when declared in Movie.kiss:
    // Mutable representation of frames in time:
    var scenes:Map<String, Scene<Set, StagePosition, StageFacing, ScreenPosition, Actor>> = [];
}
