package data;

import hscript.Parser;
import hscript.Interp;
import sys.io.File;

using StringTools;

class ScenData {
    public function new() {}

    public var floorData:Map<Int, FloorData> = [];

    public function load(file:String) {
        var scenDataLines = File.getContent(file).replace("\r", "\n").split("\n");
        var parser = new Parser();
        var interp = new Interp();

        var defining = "";
        var id = -1;
        var data:Dynamic = null;
        interp.variables["data"] = null;

        function commitData() {
            data = interp.variables["data"];
            if (data == null) return;
            trace(data);
            
            switch (defining) {
                case "floor":
                    floorData[id] = data;
                default:
            }
            data = data.clone();
        }
        function clear(?type:String) {
            if (type == null) type = defining;
            data = switch (type) {
                case "floor":
                    new FloorData();
                default:
                    null;
            };
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
                    line = line.replace("fl_", "data.");
                } else if (line == "clear;") {
                    line = "clear();";
                }
                trace(line);
                interp.execute(parser.parseString(line));
            }
        }

        // Commit the last data object that was defined:
        commitData();
    }
}
