package hollywoo;

import hollywoo.Scene;

enum Appearance {
    FirstAppearance;
    ReAppearance; // Could count the number of appearances with an int, but I don't see any reason that would be important
}

typedef Continuation = Void -> Void;

interface Director<Set, StagePosition, StageFacing, ScreenPosition, Actor> {
    function showScene(scene:Scene<Set, StagePosition, StageFacing, ScreenPosition, Actor>, appearance:Appearance, cc:Continuation):Void;
    function showCharacter(character:Character<StagePosition, StageFacing, Actor>, appearance:Appearance, cc:Continuation):Void;
    function waitForInputOrDelay(delaySeconds:Float, cc:Continuation):Void;
    function showDialog(speakerName:String, type:SpeechType<StagePosition, StageFacing, Actor>, wryly:String, dialog:String, cc:Continuation):Void;
}
