package data.blades;

import haxe.iterators.DynamicAccessIterator;
import hscript.Parser;
import hscript.Interp;
import sys.io.File;
import sys.FileSystem;
import flixel.FlxSprite;
import flixel.util.FlxColor;

using Reflect;
using StringTools;
using haxe.io.Path;

class ScenData {
    private function new() {}

    public var floorData:Map<Int, FloorData> = [];
    public var terrainData:Map<Int, TerrainData> = [];
    public var creatureData:Map<Int, CreatureData> = [];
    public var itemData:Map<Int, ItemData> = [];

    private var spriteSheets:Map<Int, FlxSprite> = [];

    private var data = "";

    public static function coreData() {
        var d = new ScenData();

        // TODO find the proper data path with the currently installed BoA depending on mac/windows
        d.data = "Data";

        // load core data:
		d.load('${d.data}/corescendata.txt');
		d.load('${d.data}/corescendata2.txt');
  
		d.test();
        
        return d;
    }

    private function floorOrTerrainSpriteSheet(num:Int) {
        if (spriteSheets.exists(num)) {
            return spriteSheets[num];
        }

        var path = '$data/Terrain Graphics/G$num.bmp';
        if (!FileSystem.exists(path)) return null;
        spriteSheets[num] = SpriteSheet.fromSimpleBmp(path, 46, 55);
        return spriteSheets[num];
    }

    function emptySprite() {
        var s = new FlxSprite(0, 0);
        s.makeGraphic(46, 55, FlxColor.TRANSPARENT);
        s.alpha = 0;
        return s;
    }

    public function floorSprite(floorId:Int) {
        if (!floorData.exists(floorId)) {
            return emptySprite();
        }        

        var fd = floorData[floorId];

        var sheet = floorOrTerrainSpriteSheet(fd.which_sheet);
        if (sheet == null) {
            return emptySprite();
        }
        var sprite = sheet.clone();

        sprite.animation.frameIndex = fd.which_icon;

        // TODO if it's animated add the animations

        return sprite;
    }
    
    public function terrainSprite(terrainId:Int) {
        if (!terrainData.exists(terrainId)) {
            var s = new FlxSprite(0, 0);
            s.makeGraphic(46, 55, FlxColor.TRANSPARENT);
            return s;
        }
        var td = terrainData[terrainId];

        var sheet = floorOrTerrainSpriteSheet(td.which_sheet);
        if (sheet == null) {
            return emptySprite();
        }
        var sprite = sheet.clone();
        sprite.animation.frameIndex = td.which_icon;

        // TODO if it's a tall terrain combine it with the upper sprite and set its origin to offset y

        // TODO if it's animated add the animations

        return sprite;
    }

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

        assert(floorData[95].name == "Floor", "floor is floor");
        assert(floorData[95].which_sheet == 704, "floor gets the right spritesheet");
        assert(floorData[129].name == "Floor", "floors can import other floors' data");
        assert(floorData[129].which_sheet == 704, "floors can import other floors' data");
        assert(floorData[129].specialProperty() == BlockedToNPCs, "blocked special property becomes enum");
        assert(terrainData[12].name == "Door", "door is door");
        assert(terrainData[404].name == "Hitching Post", "multi-token name string");

        assert(creatureData[23].field("start_item")[2] == 55, "array properties (nephil starter item)");
        assert(creatureData[23].field("start_item_chance")[2] == 100, "array properties (nephil starter item)");

        trace('$passed assertions passed');
        if (failed.length > 0) {
            trace('${failed.length} assertions failed: $failed');
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
                case "creature":
                    creatureData;
                case "item":
                    itemData;
                default:
                    null;
            };
        }

        function commitData() {
            data = interp.variables["data"];
            if (data == null) return;
            
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
                case "creature":
                    new CreatureData();
                case "item":
                    new ItemData();
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

        function _import(id) {
            data = mapFor(defining)[id].clone();
            interp.variables["data"] = data;
        }

        interp.variables["beginDefine"] = beginDefine;
        interp.variables["beginscendatascript"] = null;
        interp.variables["clear"] = clear;
        interp.variables["_import"] = _import;

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
                } else if (line.startsWith("cr_")) {
                    line = "data." + line.substr(3);
                } else if (line.startsWith("it_")) {
                    line = "data." + line.substr(3);
                } else if (line == "clear;") {
                    line = "clear();";
                } else if (line.startsWith("import =")) {
                    line = "_" + line.replace("=", "(").replace(";", ");");
                }

                // Wrap array assignments:
                if (line.startsWith("data.")) {
                    var tokens = line.split(" ");
                    var isString = false;
                    for (token in tokens) {
                        if (token.indexOf('"') != -1)
                            isString = true;
                    }
                    // <thing> = <value> or <thing> <index> = <value>
                    if (!isString && tokens.length > 3) {
                        line = tokens[0] + '[${tokens[1]}] = ' + tokens[3];
                    }
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
