package ktxt2;

import js.html.Document;
import js.html.Window;
import js.html.Element;
import js.html.TextAreaElement;
import js.html.ScrollBehavior;
import js.Lib;
import ktxt2.EditorExterns;
import ktxt2.KTxt2;
import kiss.Prelude;
import kiss.Stream;

using StringTools;

typedef MessageToEditor = {
    type:String,
    ?text:String
};

typedef EditorState = {
    text:String,
    scrollY:Float,
    elementScrollY:Int,
    activeEditorIdx:Int,
    startCursorPos:Int,
    endCursorPos:Int
};

@:build(kiss.Kiss.build())
class KTxt2Editor {}
