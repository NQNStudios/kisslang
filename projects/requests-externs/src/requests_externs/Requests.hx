package requests_externs;

import haxe.extern.EitherType;
import python.Dict;
import python.KwArgs;
import requests_externs.Response;

typedef NativeRequestKwArgs = {
    ?headers:Dict<String, String>
}

typedef RequestKwArgs = {
    ?headers:Map<String, String>
}

@:pythonImport("requests")
extern class NativeRequests {
    public static function get(url:String, params:Dict<String, String>, ?kwArgs:KwArgs<RequestKwArgs>):NativeResponse;
}

class Requests {
    public static function get(url:String, params:Map<String, String>, ?kwArgs:KwArgs<RequestKwArgs>):NativeResponse {
        return NativeRequests.get(url, mapToDict(params), kwArgs);
    }

    static function mapToDict(?map:Map<String,String>) {
        if (map == null) return null;
        var dict = new Dict<String, String>();
        for (key => value in map) {
            dict.set(key, value);
        }
        return dict;
    }

    static function kwArgsToNativeKwArgs(kwArgs:RequestKwArgs) {
        return {
            headers: mapToDict(kwArgs.headers)
        };
    }
}
