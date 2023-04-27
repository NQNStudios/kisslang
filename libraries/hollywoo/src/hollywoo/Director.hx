package hollywoo;

import hollywoo.Scene;
import hollywoo.Movie;
import haxe.ds.Option;
import kiss_tools.JsonMap;
import kiss_tools.KeyShortcutHandler;

enum Appearance {
    FirstAppearance;
    ReAppearance; // Could count the number of appearances with an int, but I don't see any reason that would be important
}

typedef Continuation = Void -> Void;

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

interface Director<Set:Cloneable<Set>, Actor, Sound, Song, Prop, VoiceTrack, Camera, LightSource:Jsonable<LightSource>> {
    var movie(default, default):Movie<Set, Actor, Sound, Song, Prop, VoiceTrack, Camera, LightSource>;
    function autoZConfig():Option<AutoZConfig>;

    function shortcutHandler():KeyShortcutHandler<Continuation->Void>;

    // Implementations of Director must pause and resume the following:
    //  - current voice tracks
    //  - current sound effects
    //  - current music
    //  - input checking
    //  - tweens
    //  - credit roll
    function pause():Void;
    function resume():Void;

    function showPauseMenu(resume:Continuation):Void;

    function chooseString(prompt:String, choices:Array<String>, submit:String->Void):Void;

    function defineStagePosition(submit:StagePosition->Void):Void;
    function defineLightSource(submit:LightSource->Void):Void;

    function showSet(set:Set, time:SceneTime, perspective:ScenePerspective, appearance:Appearance, camera:Camera, cc:Continuation):Void;
    function hideSet(set:Set, camera: Camera, cc:Continuation):Void;

    function showLighting(sceneTime:SceneTime, lightSources:Array<LightSource>, camera:Camera):Void;
    function hideLighting():Void;

    function showCharacter(character:Character<Actor>, appearance:Appearance, camera:Camera, cc:Continuation):Void;
    function hideCharacter(character:Character<Actor>, camera:Camera, cc:Continuation):Void;

    function playSound(sound:Sound, volumeMod:Float, waitForEnd:Bool, cc:Continuation):Void;
    function stopSound(sound:Sound):Void;

    function playSong(song:Song, volumeMod:Float, loop:Bool, waitForEnd:Bool, cc:Continuation):Void;
    function stopSong():Void;

    function playVoiceTrack(track:VoiceTrack, volumeMod:Float, start:Float, end:Float, cc:Continuation):Void;
    function stopVoiceTrack(track:VoiceTrack):Void;

    function startWaitForInput(cc:Continuation):Void;
    function stopWaitForInput(cc:Continuation):Void;

    function showDialog(speakerName:String, type:SpeechType<Actor>, wryly:String, dialog:String, cc:Continuation):Void;
    function hideDialog():Void;

    function showTitleCard(text:Array<String>, cc:Continuation):Void;
    function hideTitleCard():Void;

    function showBlackScreen():Void;
    function hideBlackScreen():Void;

    function showProp(prop:Prop, position:StagePosition, cc:Continuation):Void;
    function hideProp(prop:Prop, cc:Continuation):Void;

    function rollCredits(credits:Array<CreditsLine>, cc:Continuation):Void;

    function doLoading(_load:Void->Void, cc:Continuation):Void;
    function cleanup():Void;
}
