package ktxt2;

import js.html.Window;

typedef VSCodeAPI = {
    function postMessage(message:Any):Void;
    function getState():Any;
    function setState(a:Any):Void;
}

@:native("")
extern class EditorExterns {
    static function acquireVsCodeApi():VSCodeAPI;
    static var window:Window;
}
