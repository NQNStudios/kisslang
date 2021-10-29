package hollywoo;

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
    OffScreen(actor:Actor);
    TextMessage(actor:Actor);
    FromPhone(actor:Actor);
    OnScreen(character:Character<StagePosition, StageFacing, Actor>);
    Custom(type:String, actor:Actor, args:Dynamic);
}

typedef Scene<Set, StagePosition, StageFacing, ScreenPosition, Actor> = {
    set:Set,
    characters:Map<String, Character<StagePosition, StageFacing, Actor>>,
    time:SceneTime,
    perspective:ScenePerspective
};
