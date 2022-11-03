package kiss_spaced_rep;

typedef CardSide = {
    show: (StudyEngine, Void->Void) -> Void,
    score: (StudyEngine, Int->Void) -> Void
};

typedef Card = {
    front: CardSide,
    back: CardSide
};
