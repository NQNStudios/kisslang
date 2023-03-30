package hollywoo;

import kiss.FuzzyMap;
import hollywoo.Director;
import hollywoo.Movie;

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

typedef Character<Actor> = {
    stagePosition:StagePosition,
    stageFacing:StageFacing,
    actor:Actor
};

enum SpeechType<Actor> {
    Super;
    OffScreen(actor:Actor);
    VoiceOver(actor:Actor);
    TextMessage(actor:Actor);
    FromPhone(actor:Actor);
    OnScreen(character:Character<Actor>);
    Custom(type:String, actor:Actor, args:Dynamic);
}

typedef StageProp<Prop> = {
    position:StagePosition,
    prop:Prop
};

typedef Scene<Set:Cloneable<Set>, Actor, Prop, Camera> = {
    set:Set,
    characters:FuzzyMap<Character<Actor>>,
    props:FuzzyMap<StageProp<Prop>>,
    time:SceneTime,
    perspective:ScenePerspective,
    camera:Camera
};
