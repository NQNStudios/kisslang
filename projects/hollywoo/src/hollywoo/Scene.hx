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
    characters:Map<String, Character<StagePosition, StageFacing, Actor>>,
    propsOnScreen:Map<String, Prop>,
    // TODO props on stage
    time:SceneTime,
    perspective:ScenePerspective
};
