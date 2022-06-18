package data.blades;

using Type;
using Reflect;

enum ItemVariety {
    Null;
    OneHand;
    TwoHand;
    Gold;
    Food;
    ThrownMissile;
    Bow;
    Potion;
    Scroll;
    WandOrRod;
    Tool;
    Pants;
    Shield;
    Armor;
    Helm;
    Gloves;
    Boots;
    Cloak;
    Ring;
    Necklace;
    Bracelet;
    Object;
    Crossbow;
    Arrows;
    Bolts;
}

class ItemData {
    public function new() {}
    
    public function clone():ItemData {
        var id = new ItemData();
        for (field in ItemData.getInstanceFields()) {
            try {    
                id.setField(field, this.field(field));
            } catch (e) {
                // can't set functions in c++
            }
        }
        return id;
    }

    public var name = "";
    public var full_name = "";
    private var variety = 0;
    public function getVariety() {
        return ItemVariety.createEnumIndex(variety);
    }
    public var damage_per_level = 0;
    public var bonus = 0;
    private var weapon_skill_used = 4;
    // TODO public getter to convert weapon skill to a skill enum using the skill numbers in the appendix
    public var protection = 0;
    public var charges = 0;
    public var encumbrance = 0;
    public var floor_which_sheet = 0;
    public var floor_which_icon = 0;
    // TODO implement icon adjustments
    public var icon_adjust = 0;
    public var inventory_icon = 0;
    private var ability_1 = -1;
    private var ability_str_1 = 0;
    private var ability_2 = -1;
    private var ability_str_2 = 0;
    private var ability_3 = -1;
    private var ability_str_3 = 0;
    private var ability_4 = -1;
    private var ability_str_4 = 0;
    // TODO public getters for ability types as an enum
    public var special_class = 0;
    public var value = 0;
    private var weight = 0;
    public function getWeight():Float {
        return weight / 10.0;
    }
    private var identified = 0;
    public function isIdentified() {
        return identified == 1;
    }
    private var magic = 0;
    public function isMagic() {
        return magic == 1;
    }
    private var cursed = 0;
    public function isCursed() {
        return cursed == 1;
    }
    private var once_per_day = 0;
    public function oncePerDay() {
        return once_per_day == 1;
    }
    private var junk_item = 0;
    public function junkItem() {
        return junk_item == 1;
    }
    private var missile_anim_type = 0;
    // TODO make missile anim type publically available as an enum
}