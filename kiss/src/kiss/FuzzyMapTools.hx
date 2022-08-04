package kiss;

import haxe.Json;
import haxe.ds.StringMap;
using hx.strings.Strings;

typedef MapInfo = {
    file:String,
    matches:Map<String,Dynamic>
};

class FuzzyMapTools {
    static var serializingMaps = new Map<StringMap<Dynamic>, MapInfo>();

    /**
    * FuzzyMap is highly inefficient, so you may wish to memoize the matches that it makes before
    * releasing your project. FuzzyMapTools.serializeMatches() helps with this
    */
    public static function serializeMatches(m:StringMap<Dynamic>, file:String) {
        serializingMaps[m] = { file: file, matches: new Map() };
    }

    public static function fuzzyMatchScore(key:String, fuzzySearchKey:String) {
        return 1 - (key.toLowerCase().getLevenshteinDistance(fuzzySearchKey.toLowerCase()) / Math.max(key.length, fuzzySearchKey.length));
    }

    static var threshold = 0.4;

    public static function bestMatch<T>(map:FuzzyMap<T>, fuzzySearchKey:String, ?throwIfNone=true):String {
        if (map.existsExactly(fuzzySearchKey)) return fuzzySearchKey;

        var bestScore = 0.0;
        var bestKey = null;

        for (key in map.keys()) {
            var score = fuzzyMatchScore(key, fuzzySearchKey);
            if (score > bestScore) {
                bestScore = score;
                bestKey = key;
            }
        }

        if (bestScore < threshold) {
            if (throwIfNone)
                throw 'No good match for $fuzzySearchKey in $map -- best was $bestKey with $bestScore';
            else
                return null;
        }

        #if (test || debug)
        trace('Fuzzy match $bestKey for $fuzzySearchKey score: $bestScore');
        #end
        
        return bestKey;
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