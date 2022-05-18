package data;

using Type;
using Reflect;

import flixel.input.keyboard.FlxKey;

enum FloorShimmerType {
    None;
    LightToDark;
    Water;
}

enum FloorSpecialProperty {
    Nothing;

    // For dice-based properties, special_strength is the size of the dice.
    FireDamage2Dice;
    ColdDamage2Dice;
    MagicDamage2Dice;
    PoisonLevels1Die50Percent;
    DiseaseLevels1Die50Percent;
    
    BlockedToNPCs;
    NoRest;

    // Call the scenario script with the number special_strength
    CallScenarioScript;
}

class FloorData {
    public function new() {}
    
    public function clone():FloorData {
        var fd = new FloorData();
        for (field in FloorData.getClassFields()) {
            fd.setField(field, this.field(field));
        }
        return fd;
    }
    
    public var name:String = "";
    public var which_sheet:Int = 0;
    public var which_icon:Int = 0;
    public var icon_adjust:Int = 0;
    public var ed_which_sheet:Int = 0;
    public var ed_which_icon:Int = 0;
    private var blocked:Int = 0;
    public function isBlocked() {
        return blocked == 1;
    }
    public var step_sound:Int = -1;
    public var light_radius:Int = 0;
    public var floor_height_pixels:Int = 0;
    private var special_property:Int = 0;
    public function specialProperty() {
        return FloorSpecialProperty.createEnumIndex(special_property);
    }
    public var special_strength:Int = 0;
    public var is_water:Bool = false;
    public var is_floor:Bool = false;
    public var is_ground:Bool = false;
    public var is_rough:Bool = false;
    public var fly_over:Bool = false;
    private var shortcut_key:Int = -1;
    public function shortcutKey() {
        return if (shortcut_key == -1) {
            NONE;
        } else {
            FlxKey.A + shortcut_key;
        };
    }
    public var anim_steps:Int = 0;
    private var shimmers:Int;
    public function shimmerType() {
        return FloorShimmerType.createEnumIndex(shimmers);
    }
    public var out_fight_town_used:Int = 1000;
}
