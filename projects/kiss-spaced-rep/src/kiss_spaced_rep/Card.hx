package kiss_spaced_rep;

typedef CardSide = {
    show: (Void->Void) -> Void,
    score: (Int->Void) -> Void
};

typedef Card = {
    front: CardSide,
    back: CardSide
};
