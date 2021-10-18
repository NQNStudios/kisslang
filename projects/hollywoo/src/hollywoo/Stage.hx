package hollywoo;

import kiss.EmbeddedScript;

enum SceneTime {
    Morning;
    Day;
    Evening;
    Night;
}

enum ScenePerspective {
    Interior;
    Exterior;
    Mixed;
}

typedef Character<StagePosition, StageFacing, Actor> = {
    stagePosition:StagePosition,
    stageFacing:StageFacing,
    actor:Actor
};

typedef Scene<Set, StagePosition, StageFacing, ScreenPosition, Actor> = {
    set:Set,
    characters:Map<String, Character<StagePosition, StageFacing, Actor>>,
    time:SceneTime,
    perspective:ScenePerspective
};

/**
 * Model of a Hollywoo film
 */
@:build(kiss.Kiss.build())
class Stage<Set, StagePosition, StageFacing, ScreenPosition, Actor> extends kiss.EmbeddedScript {
    // Mostly immutable, reusable resources:
    var sets:Map<String, Set> = [];
    var actors:Map<String, Actor> = [];

    
    // Mutable representation of frames in time:
    var scenes:Map<String, Scene<Set, StagePosition, StageFacing, ScreenPosition, Actor>> = [];
}
