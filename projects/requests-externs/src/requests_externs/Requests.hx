package requests_externs;

import haxe.extern.EitherType;
import python.Dict;
import python.KwArgs;

typedef NativeRequestKwArgs = {
    ?headers:Dict<String, String>,
    ?timeout:Float
}

typedef RequestKwArgs = {
    ?headers:Map<String, String>,
    ?timeout:Float
}

@:pythonImport("requests")
extern class NativeRequests {
    public static function get(url:String, params:Dict<String, String>, ?kwArgs:KwArgs<NativeRequestKwArgs>):Dynamic;
}

class Requests {
    public static function get(url:String, params:Map<String, String>, ?kwArgs:RequestKwArgs):Dynamic {
        return NativeRequests.get(url, mapToDict(params), kwArgsToNativeKwArgs(kwArgs));
    }

    static function mapToDict(?map:Map<String, String>) {
        if (map == null)
            return null;
        var dict = new Dict<String, String>();
        for (key => value in map) {
            dict.set(key, value);
        }
        return dict;
    }

    static function kwArgsToNativeKwArgs(?kwArgs:RequestKwArgs) {
        if (kwArgs == null)
            return null;
        return {
            headers: mapToDict(kwArgs.headers),
            timeout: kwArgs.timeout
        };
    }
}
