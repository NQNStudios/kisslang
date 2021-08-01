package requests_externs;

import haxe.extern.EitherType;
import python.Dict;
import python.KwArgs;
import requests_externs.Response;

typedef RequestKwArgs = {
    ?headers:Map<String, String>
}

@:pythonImport("requests")
extern class NativeRequests {
    public static function get(url:String, params:Dict<String, String>, ?kwArgs:KwArgs<RequestKwArgs>):Response;
}

class Requests {
    public static function get(url:String, params:Map<String, String>, ?kwArgs:KwArgs<RequestKwArgs>):Response {
        var dict = new Dict<String, String>();
        for (param => value in params) {
            dict.set(param, value);
        }
        return NativeRequests.get(url, dict, kwArgs);
    }
}
