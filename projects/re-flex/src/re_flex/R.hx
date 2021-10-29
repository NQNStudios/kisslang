package re_flex;

import kiss.Prelude;
import kiss.List;
#if hxnodejs
import js.lib.RegExp;
import haxe.DynamicAccess;
#end

typedef RMatch = {
    left:String,
    match:String,
    right:String,
    #if hxnodejs
    groups:Array<String>,
    namedGroups:DynamicAccess<String>,
    #end
    group:Int->String
};

@:build(kiss.Kiss.build())
class R {}
