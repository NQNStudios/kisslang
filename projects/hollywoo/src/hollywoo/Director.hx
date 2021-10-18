package hollywoo;

import hollywoo.Stage;

enum Appearance {
    FirstAppearance;
    ReAppearance; // Could count the number of appearances with an int, but I don't see any reason that would be important
}

typedef Continuation = Void -> Void;

interface Director<Set, StagePosition, StageFacing, ScreenPosition, Actor> {
    function showSet(set:Set, appearance:Appearance, cc:Continuation):Void;
    function showCharacter(character:Character<StagePosition, StageFacing, Actor>, appearance:Appearance, cc:Continuation):Void;
}
