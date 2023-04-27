package kiss_spaced_rep;

typedef Continuation = Void -> Void;

interface StudyEngine {
    function clear():Void;
    function print(s:String):Void;
    function println(s:String):Void;
    function showImage(s:String):Void;
    function delayForUserInput(cc:Continuation, ?text:String):Void;
    function getUserInput(resolve:String->Void):Void;
    function promptForRefresh(refresh:Void->Void):Void;
}
