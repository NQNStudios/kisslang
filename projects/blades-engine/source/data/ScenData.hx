package data;

import hscript.Parser;
import hscript.Interp;
import sys.io.File;

using StringTools;

class ScenData {
    public function new() {}

    public var floorData:Map<Int, FloorData> = [];
    public var terrainData:Map<Int, TerrainData> = [];

    static var failed:Array<String> = [];
    static var passed = 0;
    static function assert(e:Bool, msg="") {
        if (!e) {
            failed.push(msg);
        } else {
            passed++;
        };
    }

    // Core data unit tests:
    public function test() {
        failed = [];
        passed = 0;

        assert(floorData[129].name == "Floor", "floors can import other floors' data");
        assert(terrainData[12].name == "Door", "door is door");

        trace('$passed assertions passed');
        if (failed.length > 0) {
            trace('Assertions failed: $failed');
            Sys.exit(1);
        }

    }


    public function load(file:String) {
        var scenDataLines = File.getContent(file).replace("\r", "\n").split("\n");
        var parser = new Parser();
        var interp = new Interp();

        var defining = "";
        var id = -1;
        var data:Dynamic = null;
        interp.variables["data"] = null;

        function mapFor(type:String):Map<Int,Dynamic> {
            return switch (type) {
                case "floor":
                    floorData;
                case "terrain":
                    terrainData;
                default:
                    null;
            };
        }

        function commitData() {
            data = interp.variables["data"];
            if (data == null) return;
            trace(data);
            
            mapFor(defining)[id] = data;
            data = data.clone();
            interp.variables["data"] = data;
        }
        function clear(?type:String) {
            if (type == null) type = defining;
            data = switch (type) {
                case "floor":
                    new FloorData();
                case "terrain":
                    new TerrainData();
                default:
                    null;
            };
            interp.variables["data"] = data;
        }
        function beginDefine(type, tid) {
            commitData();

            if (defining != type) {
                clear(type);
            }
            interp.variables["data"] = data;

            defining = type;
            id = tid;
        }
        interp.variables["beginDefine"] = beginDefine;
        interp.variables["beginscendatascript"] = null;
        interp.variables["clear"] = clear;

        for (line in scenDataLines) {
            var commentIndex = line.indexOf("//");
            if (commentIndex != -1) {
                line = line.substr(0, commentIndex);
            }
            line = line.trim();
            if (line.length > 0) {
                if (line.startsWith("begindefine")) {
                    line = "beginDefine('" + line.replace("begindefine", "").replace(" ", "',").replace(";", ");");
                } else if (line.startsWith("fl_")) {
                    line = "data." + line.substr(3);
                } else if (line.startsWith("te_")) {
                    line = "data." + line.substr(3);
                } else if (line == "clear;") {
                    line = "clear();";
                }
                try {
                    interp.execute(parser.parseString(line));
                } catch (e) {
                    trace('line `$line` failed because $e');
                } 
            }
        }

        // Commit the last data object that was defined:
        commitData();
    }
}
