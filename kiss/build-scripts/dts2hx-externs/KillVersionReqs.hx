package;

import sys.io.File;
import sys.FileSystem;
import haxe.Json;

class KillVersionReqs {
    static function main() {
        var libs = FileSystem.readDirectory("libs");
        for (lib in libs) {
            var haxelib = 'libs/$lib/$lib/haxelib.json';
            var json = Json.parse(File.getContent(haxelib));
            for (dependency => version in (json.dependencies : haxe.DynamicAccess<String>)) {
                json.dependencies[dependency] = "";
            }
            File.saveContent(haxelib, Json.stringify(json)); 
        }
    }
}