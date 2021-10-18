package hollywoo.text;

import hollywoo.Stage;

typedef TextSet = {
    name:String,
    description:String
}

enum TextStagePosition {
    OnStage;
    OffStage;
}

typedef TextStageFacing = String;

typedef TextScreenPosition = Int; // number of line breaks to precede a SUPER

typedef TextCharacter = Character<TextStagePosition, TextStageFacing, TextActor>;

typedef TextActor = {
    name:String,
    description:String
};

typedef TextStage = Stage<TextSet, TextStagePosition, TextStageFacing, TextScreenPosition, TextActor>;
