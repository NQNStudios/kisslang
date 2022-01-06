package hollywoo;

import hollywoo.Scene;
import hollywoo.Movie;

enum Appearance {
    FirstAppearance;
    ReAppearance; // Could count the number of appearances with an int, but I don't see any reason that would be important
}

typedef Continuation = Void -> Void;

interface Director<Set, StagePosition, StageFacing, ScreenPosition, Actor, Sound, Song, Prop, VoiceTrack> {
    var movie(default, default):Movie<Set, StagePosition, StageFacing, ScreenPosition, Actor, Sound, Song, Prop, VoiceTrack>;
    function showScene(scene:Scene<Set, StagePosition, StageFacing, ScreenPosition, Actor, Prop>, appearance:Appearance, cc:Continuation):Void;
    function showCharacter(character:Character<StagePosition, StageFacing, Actor>, appearance:Appearance, cc:Continuation):Void;
    function hideCharacter(character:Character<StagePosition, StageFacing, Actor>, cc:Continuation):Void;
    function moveCharacter(character:Character<StagePosition, StageFacing, Actor>, toPos:StagePosition, toFacing:StageFacing, cc:Continuation):Void;
    function swapCharacters(a:Character<StagePosition, StageFacing, Actor>, b:Character<StagePosition, StageFacing, Actor>, cc:Continuation):Void;
    function playSound(sound:Sound, volumeMod:Float, waitForEnd:Bool, cc:Continuation):Void;
    function playSong(song:Song, volumeMod:Float, loop:Bool, waitForEnd:Bool, cc:Continuation):Void;
    function stopSong():Void;
    function playVoiceTrack(track:VoiceTrack, volumeMod:Float, start:Float, end:Float, cc:Continuation):Void;
    function stopVoiceTrack(track:VoiceTrack):Void;
    function startWaitForInput(cc:Continuation):Void;
    function stopWaitForInput():Void;
    function showDialog(speakerName:String, type:SpeechType<StagePosition, StageFacing, Actor>, wryly:String, dialog:String, cc:Continuation):Void;
    function hideDialog():Void;
    function showTitleCard(text:Array<String>, cc:Continuation):Void;
    function hideTitleCard():Void;
    function showPropOnScreen(prop:Prop, position:ScreenPosition, cc:Continuation):Void;
    // TODO showPropOnStage
    function hideProp(prop:Prop, cc:Continuation):Void;

    function rollCredits(credits:Array<CreditsLine>, cc:Continuation):Void;

    function cleanup():Void;
}
