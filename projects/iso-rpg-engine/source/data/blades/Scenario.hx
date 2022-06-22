package data.blades;

import kiss.ByteStream;

import data.blades.TileMap;

using StringTools;

class Scenario {
    public var outdoorSections:TileArray<TileMap> = [];
    public var towns:Array<TileMap> = [];
    public var name = "";
    public var description1 = "";
    public var description2 = "";
    public var credit1 = "";
    public var credit2 = "";

    public var intro:Array<Array<String>>;

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
        assert(scen.description1.startsWith("Everything in the valley is dying."), '${scen.description1} is the wrong description');
        assert(scen.description2 == 'Can you cure them?', '${scen.description2} is the wrong description');
        assert(scen.intro[0][0].startsWith("Adventurers, at last!"), 'problem with ${scen.intro[0][0]}');
        assert(scen.intro[0][0].endsWith("rewards to earn!"), 'problem with ${scen.intro[0][0]}');
        assert(scen.intro[0][1] == 'Soon you will be heroes, if you have anything to say about it.', 'problem with ${scen.intro[0][1]}');
        assert(scen.intro[0][5] == 'Apparently, you are to go to Skylark Vale and investigate a minor plague or disaster or something. They aren\'t specific.', 'problem with ${scen.intro[0][5]}');
        assert(scen.intro[1][2] == "You've just stayed the night in your room at the fort. You had a good night's sleep and a good meal. Now the sun is rising. Finally, it's time to go out and be heroes!", 'problem with ${scen.intro[1][2]}');
        assert(scen.intro[1][3] == "", 'problem with ${scen.intro[1][3]}');
        assert(scen.outdoorSections[0][0].script == "o00Northweste", 'problem with outdoor scripts[0][0]');
        assert(scen.outdoorSections[2][2].script == "o22Valley Ent", 'problem with outdoor scripts[2][2]');

        trace('$passed assertions passed');
        if (failed.length > 0) {
            trace('${failed.length} assertions failed: $failed');
            Sys.exit(1);
        }
    }

    public static function fromBasFile(file) {
        var scen = new Scenario();
        var stream = ByteStream.fromFile(file);
        
        // TODO
        stream.unknownBytes(11);

        var numTowns = stream.readUInt16();
        var outdoorWidth = stream.readUInt16();
        var outdoorHeight = stream.readUInt16();

        // TODO
        stream.unknownBytes(5);
        // scenario title, 49 char max, 0-terminated
        scen.name = stream.readCString(49);

        // in valleydy, it's 07 6C
        // in stealth, it's 07 6D
        stream.unknownBytes(2);

        scen.description1 = stream.readCString();
        stream.skipZeros();
        scen.credit1 = stream.readCString();
        stream.skipZeros();
        // weirdly, this is the one that can be changed in the editor, and the only one to appear in "About this scenario"
        scen.credit2 = stream.readCString();
        stream.skipZeros();
        // Weirdly, this doesn't seem to appear anywhere, but in the case of valleydy, it would make a punchier description
        scen.description2 = stream.readCString();
        stream.skipZeros();

        // TODO in valleydy and stealth, it's 02 26 02 27 FF FF
        stream.unknownBytes(6);

        // Intro paragraphs are c-strings fitting in 16*16 bytes.
        // After the 0 terminator there are usually junk characters.
        // 3 pages of 6 paragraphs
        scen.intro = [for (page in 0...3) {
            [for (paragraph in 0...6)
                stream.readCString(16*16-1)];
        }];

        // After the intro paragpraphs there are a lot of unknown bytes that could possibly be metadata of the first outdoor section's tiles
        // 1D30 08 is the first outdoor section
        stream.unknownUntil("0x1D38");

        for (x in 0...outdoorWidth) {
            scen.outdoorSections[x] = [];
        }
        // outdoor section rows
        for (y in 0...outdoorHeight) {
            for (x in 0...outdoorWidth) {
                var outdoorWidth = 48;
                var outdoorHeight = 48;

                // section name, max length 19, followed by floor tile columns
                // the type Outdoors(false) is temporary. the above/underground byte comes at the end
                var sec = new TileMap(outdoorWidth, outdoorHeight, stream.readCString(19), Outdoors(false));

                for (x in 0...outdoorWidth) {
                    for (y in 0...outdoorHeight) {
                        sec.setFloor(x, y, stream.readByte());
                    }
                }

                // floor heights
                for (x in 0...outdoorWidth) {
                    for (y in 0...outdoorHeight) {
                        sec.setFloorHeight(x, y, stream.readByte());
                    }
                }

                // 1 byte of padding to align the int16s
                // terrain
                for (x in 0...outdoorWidth) {
                    for (y in 0...outdoorHeight) {
                        // these are big-endian
                        sec.setTerrain(x, y, 256 * stream.readByte() + stream.readByte());
                    }
                }

                stream.tracePosition();
                
                // TODO Includes things like area descriptions and sign text.
                // God, I hope this is a fixed length for all outdoor sections.
                stream.unknownBytes(3620);

                sec.script = stream.readCString(14);
                sec.type = switch (stream.readByte()) {
                    case 0:
                        Outdoors(true);
                    case 1:
                        Outdoors(false);
                    default:
                        stream.tracePosition();
                        throw 'bad byte for aboveground/underground';
                };
                stream.paddingBytes(20);
                
                scen.outdoorSections[x][y] = sec;
            }
        }
        
        stream.tracePosition();

        var townIdx = 0;
        // TODO find an end condition for this loop
        while (true) {
            var name = stream.readCString();
            
            // TODO I'm guessing these zeros identify light level, surface/underground,
            // creature respawn chance, map size
            stream.skipZeros();

            var map = new TileMap(48, 48, name, Town(false, {wallSheet1: 601, wallSheet2: 600}));

            

            scen.towns[townIdx++] = map;
            
            // TODO don't
            break;
        }

        // 1E274: Fort Talrus (name of town 0)

        // 27866 bytes (medium town, 48x48)

        // 24F4E: Sweetgrove

        // 36826 bytes (large town, 64x64)

        // 2DF28: Blinlock

        // 72922 bytes (medium town, 48x48)

        // well I guess that means they aren't uniform size between small/medium/large...

        // 3FC02: Marralis
        
        // (medium town, 48x48)

        // TODO all the other stuff
        return scen;
    }
}
