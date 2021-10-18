package hollywoo.text;

import hollywoo.text.TextStage;
import hollywoo.Director;

class TextDirector implements Director<TextSet, TextStagePosition, TextStageFacing, TextScreenPosition, TextActor> {
    public function new() {}

    public function showSet(set:TextSet, appearance:Appearance, cc:Continuation) {
        switch (appearance) {
            case FirstAppearance:
                Sys.println('-- ${set.name} --');
                Sys.println(set.description);
            case ReAppearance:
                Sys.println('-- back at the ${set.name}');
        }
        cc();
    }

    public function showCharacter(character:TextCharacter, appearance:Appearance, cc:Continuation) {
        switch ([appearance, character.stagePosition]) {
            case [_, OffStage]:
            case [FirstAppearance, OnStage]:
                Sys.println('A ${character.actor.description} is onstage. This is ${character.actor.name}');
            case [ReAppearance, OnStage]:
                Sys.println('${character.actor.name} is here');
        }
        cc();
    }
}