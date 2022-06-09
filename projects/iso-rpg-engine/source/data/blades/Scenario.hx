package data.blades;

import kiss.ByteStream;

import data.blades.TileMap;

class Scenario {
    private var outdoorSections:TileArray<TileMap>;
    private var towns:Array<TileMap>;
    private var name = "";
    private var decription = "";

    function new() {

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

    public static function test() {
        var scen = fromBasFile("Blades of Avernum Scenarios/Valley of Dying Things/valleydy.bas");
        
        assert(scen.name == "Valley of Dying Things", '${scen.name} is the wrong title');

        trace('$passed assertions passed');
        if (failed.length > 0) {
            trace('${failed.length} assertions failed: $failed');
            Sys.exit(1);
        }
    }

    public static function fromBasFile(file) {
        var scen = new Scenario();
        var stream = ByteStream.fromFile(file);
        
        function unknownBytes(num:Int) {
            trace('Warning: ignoring $num unknown bytes');
            for (_ in 0...num) stream.readByte();
        }

        function paddingBytes(num) {
            for (_ in 0...num) stream.readByte();
        }

        // TODO
        unknownBytes(11);

        var numTowns = stream.readUInt16();
        var outdoorWidth = stream.readUInt16();
        var outdoorHeight = stream.readUInt16();
        trace(outdoorWidth);
        trace(outdoorHeight);

        // TODO
        unknownBytes(5);
        // TODO scenario title 49 bytes 0-terminated
        scen.name = stream.readCString();
        paddingBytes(49 - scen.name.length);

        return scen;
    }
}
