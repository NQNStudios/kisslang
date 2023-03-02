package hollywoo;

import hollywoo.Scene;
import hollywoo.Movie;
import haxe.ds.Option;

enum Appearance {
    FirstAppearance;
    ReAppearance; // Could count the number of appearances with an int, but I don't see any reason that would be important
}

typedef Continuation = Void -> Void;

typedef StagePosition = {
    x:Float,
    y:Float,
    z:Float,
};

enum StageFacing {
    TowardsCharacter(name:String);
    AwayFromCharacter(name:String);
    TowardsPosition(name:String);
    AwayFromPosition(name:String);
}

typedef AutoZConfig = {
    zPerLayer:Float,
    frontLayer:Int
};

interface Director<Set:Cloneable<Set>, ScreenPosition, Actor, Sound, Song, Prop, VoiceTrack> {
    var movie(default, default):Movie<Set, ScreenPosition, Actor, Sound, Song, Prop, VoiceTrack>;
    var autoZConfig(default,null):Option<AutoZConfig>;
    function showSet(set:Set, time:SceneTime, perspective:ScenePerspective, appearance:Appearance, cc:Continuation):Void;
    function hideSet(set:Set, cc:Continuation):Void;
    function showCharacter(character:Character<Actor>, appearance:Appearance, cc:Continuation):Void;
    function hideCharacter(character:Character<Actor>, cc:Continuation):Void;
    function playSound(sound:Sound, volumeMod:Float, waitForEnd:Bool, cc:Continuation):Void;
    function stopSound(sound:Sound):Void;
    function playSong(song:Song, volumeMod:Float, loop:Bool, waitForEnd:Bool, cc:Continuation):Void;
    function stopSong():Void;
    function playVoiceTrack(track:VoiceTrack, volumeMod:Float, start:Float, end:Float, cc:Continuation):Void;
    function stopVoiceTrack(track:VoiceTrack):Void;
    function startWaitForInput(cc:Continuation):Void;
    function stopWaitForInput():Void;
    function showDialog(speakerName:String, type:SpeechType<Actor>, wryly:String, dialog:String, cc:Continuation):Void;
    function hideDialog():Void;
    function showTitleCard(text:Array<String>, cc:Continuation):Void;
    function hideTitleCard():Void;
    function showBlackScreen():Void;
    function hideBlackScreen():Void;
    function showPropOnScreen(prop:Prop, position:ScreenPosition, cc:Continuation):Void;
    // TODO showPropOnStage
    function hideProp(prop:Prop, cc:Continuation):Void;

    function rollCredits(credits:Array<CreditsLine>, cc:Continuation):Void;

    function cleanup():Void;
}
