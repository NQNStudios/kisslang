package hollywoo;

import kiss.FuzzyMap;

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

enum SpeechType<StagePosition, StageFacing, Actor> {
    Super;
    OffScreen(actor:Actor);
    VoiceOver(actor:Actor);
    TextMessage(actor:Actor);
    FromPhone(actor:Actor);
    OnScreen(character:Character<StagePosition, StageFacing, Actor>);
    Custom(type:String, actor:Actor, args:Dynamic);
}

typedef Scene<Set, StagePosition, StageFacing, ScreenPosition, Actor, Prop> = {
    set:Set,
    characters:FuzzyMap<Character<StagePosition, StageFacing, Actor>>,
    propsOnScreen:FuzzyMap<Prop>,
    // TODO props on stage
    time:SceneTime,
    perspective:ScenePerspective
};
