package data.blades;

using Type;
using Reflect;

import data.blades.FloorData;

import flixel.input.keyboard.FlxKey;
import kiss.Prelude;
import kiss.Kiss;

enum Direction {
    North;
    NorthWest;
    West;
    SouthWest;
    South;
    SouthEast;
    East;
    NorthEast;
}

enum HillDirection {
    Up(dir:Direction);
    Down(dir:Direction);
}

enum BeamHitType {
    Auto;
    Clear;
    Undefined;
    Crumble;
}

enum MirrorType {
                  //     ^
                  //     |
    ForwardSlash; // ----/
    BackSlash;    // ----\
                  //     |
                  //     v
}

enum BeamBehavior {
    SwapTerrainWhenHit;
    Fire(dir:Direction);
    Mirror(type:MirrorType);
    PowerSource;
}

enum TerrainSpecialProperty {
    Floor(prop:FloorSpecialProperty);
    Hill(dir:HillDirection);
    Beam(behavior:BeamBehavior);
    Sign;
    Container;
    Table;
    ShimmerLightAndDark;
    Waterfall(dir:Direction);
    QuickFlammable;
}

class TerrainData {
    public function new() {}
    
    public function clone():TerrainData {
        var td = new TerrainData();
        for (field in TerrainData.getInstanceFields()) {
            try {    
                td.setField(field, this.field(field));
            } catch (e) {
                // can't set functions in c++
            }
        }
        return td;
    }

    public var name:String = "";
    public var default_script:String = "Unused";
    public var which_sheet:Int = 0;
    public var which_icon:Int = 0;
    public var icon_adjust:Int = 0;
    public var ed_which_sheet:Int = 0;
    public var ed_which_icon:Int = 0;
    public var cutaway_which_sheet:Int = -1;
    public var cutaway_which_icon:Int = 0;
    public var cutaway_icon_adjust:Int = 0;
    public var icon_offset_x:Int = 0;
    public var icon_offset_y:Int = 0;
    public var second_icon:Int = -1;
    public var second_icon_offset_x:Int = 0;
    public var second_icon_offset_y:Int = 0;
    public var cutaway_second_icon:Int = -1;
    public var anim_steps:Int = 0;
    private var move_block_n:Int = 0;
    private var move_block_w:Int = 0;
    private var move_block_s:Int = 0;
    private var move_block_e:Int = 0;

    static var HILL_DIR_MAP = [
        19 => Up(West),
        20 => Up(SouthWest),
        21 => Up(South),
        22 => Up(SouthEast),
        23 => Up(East),
        24 => Up(NorthEast),
        25 => Up(North),
        26 => Up(NorthWest),
        27 => Down(SouthEast),
        28 => Down(NorthEast),
        29 => Down(NorthWest),
        30 => Down(SouthWest)
    ];

    static var BEAM_DIR_MAP = [
        32 => North,
        33 => West,
        34 => South,
        35 => East
    ];

    public function moveBlock(dir:Direction) {
        return if (full_move_block == 1) {
            true;
        } else if (full_move_block == 0) {
            false;
        } else {
            (switch (dir) {
                case North:
                    move_block_n;
                case West:
                    move_block_w;
                case South:
                    move_block_s;
                case East:
                    move_block_e;
                default:
                    throw 'bad move block direction';
            }) == 1;
        };
    }
    private var look_block_n:Int = 0;
    private var look_block_w:Int = 0;
    private var look_block_s:Int = 0;
    private var look_block_e:Int = 0;
    public function lookBlock(dir:Direction) {
        return if (full_look_block == 1) {
            true;
        } else if (full_look_block == 0) {
            false;
        } else {
            (switch (dir) {
                case North:
                    look_block_n;
                case West:
                    look_block_w;
                case South:
                    look_block_s;
                case East:
                    look_block_e;
                default:
                    throw 'bad look block direction';
            }) == 1;
        };
    }   
    private var blocks_view_n:Int = 0;
    private var blocks_view_w:Int = 0;
    private var blocks_view_s:Int = 0;
    private var blocks_view_e:Int = 0;
    public function blocksView(dir:Direction) {
        return (switch (dir) {
            case North:
                blocks_view_n;
            case West:
                blocks_view_w;
            case South:
                blocks_view_s;
            case East:
                blocks_view_e;
            default:
                throw 'bad blocks view direction';
        }) == 1;
    }   
    public var height_adj_pixels:Int = 0;
    private var suppress_floor:Int = 0;
    public function suppressFloor() {
        return suppress_floor == 1;
    }
    public var light_radius:Int = 0;
    public var step_sound:Int = -1;
    private var shortcut_key:Int = -1;
    public function shortcutKey() {
        return if (shortcut_key == -1) {
            FlxKey.NONE;
        } else {
            FlxKey.A + shortcut_key;
        };
    }
    private var crumble_type:Int = 0;
    public function crumblesByMoveMountains(level:Int) {
        return if (crumble_type > 0) {
            level >= crumble_type;
        } else {
            false;
        }
    }
    public function crumblesByBeam() {
        return beam_hit_type == 3 && crumble_type != 0;
    }
    public var terrain_to_crumble_to:Int = 0;
    private var beam_hit_type:Int = 0;
    public function beamHitType() {
        return BeamHitType.createEnumIndex(beam_hit_type);
    }
    public var hidden_town_terrain:Int = -1;
    public var swap_terrain:Int = -1;
    private var is_bridge:Int = 0;
    public function isBridge() {
        return is_bridge == 1;
    }
    private var is_road:Int = 0;
    public function isRoad() {
        return is_road == 1;
    }
    // TODO allow highlighting the sprite instead of using the old-school lettered selection system
    private var can_look_at:Int = 0;
    public function canLookAt() {
        return can_look_at == 1;
    }
    private var special_property:Int = 0;
    function specialProperty() {
        return Kiss.exp('(case special_property
                            ((when (<= 0 prop 8) prop)
                                (Floor (FloorSpecialProperty.createEnumIndex prop)))
                            ((when (HILL_DIR_MAP.exists prop) prop)
                                (Hill (dictGet HILL_DIR_MAP prop)))
                            (31 (Beam SwapTerrainWhenHit))
                            ((when (BEAM_DIR_MAP.exists prop) prop)
                                (Beam
                                    (Fire
                                        (dictGet BEAM_DIR_MAP prop))))
                            (36 (Beam (Mirror BackSlash)))
                            (37 (Beam (Mirror ForwardSlash)))
                            (38 (Beam PowerSource))
                            (39 Sign)
                            (40 Container)
                            (41 Table)
                            (42 ShimmerLightAndDark)
                            (43 (Waterfall South))
                            (44 (Waterfall East))
                            (45 QuickFlammable)
                            (otherwise (throw "undefined special_property")))');
    }
    // specialProperty() defined in .kiss file

    public var special_strength:Int = 0;

    private var draw_on_automap:Int = 0;
    public function drawOnAutomap() {
        return draw_on_automap == 1;
    }
    private var full_move_block:Int = -1;
    private var full_look_block:Int = -1;
    private var shimmers:Int = 0;
    public function shouldShimmer() {
        return shimmers == 1;
    }
    public var out_fight_town_used:Int = -1;
}