package kiss;

import haxe.Json;
import haxe.ds.StringMap;

typedef MapInfo = {
    file:String,
    matches:Map<String,Dynamic>
};

/**
 * FuzzyMap is highly inefficient, so you may wish to memoize the matches that it makes before
 * releasing your project. FuzzyMapTools helps with this
 */
class FuzzyMapTools {
    static var serializingMaps = new Map<StringMap<Dynamic>, MapInfo>();

    public static function serializeMatches(m:StringMap<Dynamic>, file:String) {
        serializingMaps[m] = { file: file, matches: new Map() };
    }

    @:allow(kiss.FuzzyMap)
    static function onMatchMade(m:StringMap<Dynamic>, key:String, value:Dynamic) {
        #if (sys || hxnodejs)
        if (serializingMaps.exists(m)) {
            var info = serializingMaps[m];
            info.matches[key] = value;
            sys.io.File.saveContent(info.file, Json.stringify(info.matches));
        }
        #end
    }

    public static function loadMatches(m:StringMap<Dynamic>, json:String) {
        var savedMatches:haxe.DynamicAccess<Dynamic> = Json.parse(json);
        for (key => value in savedMatches.keyValueIterator()) {
            m.set(key, value);
        }
    }
}