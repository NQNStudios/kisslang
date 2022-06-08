package data.blades;

using Type;
using Reflect;
import kiss.Prelude;
import kiss.Kiss;

enum MeleeAbility {
    Poison;
    Slow;
    Disease;
    Sleep;
    Paralyze;
    Acid;
    Fire;
    Cold;
    DrainXP;
    ColdDrainXP;
    Web;
}

enum RayAbility {
    CurseAndWeaken;
    TurnToStone;
    Charm;
    Sleep;
    Paralyze;
    DrainSP;
    Confuse;
    Terrify;
    Fire;
    MagicDamage;
}

enum ThrowAbility {
    Web4; // range 4
    Rocks;
    Spines; // damage and paralysis
}

enum FieldAbility {
    Fire;
    Cold;
    AntiMagic;
    Sleep;
    Stink;
    Blade;
}

enum BreathAbility {
    Fire;
    Cold;
    Acid;
    Darkness;
}

enum SpecialAbility {
    None;
    Melee(a: MeleeAbility);
    Ray(a: RayAbility);
    Throw(a: ThrowAbility);
    Radiate(a: FieldAbility);
    Breath(a: BreathAbility);
    Invisible;
    SplitsWhenHit;
    ForceCage;
}

enum Attitude {
    Friendly;
    Neutral;
    HostileA;
    HostileB;
}

enum Species {
    Human;
    Humanoid;
    Nephil; // bonus missle weapons and dexterity
    Slith; // bonus pole weapons and fire resistance
    Giant;
    Reptile; // won't pick up or use items
    Beast; // same
    Demon; // same + vulnerable to Repel Spirit at high levels + immune to mental spells
    Undead; // same + vulnerable to Repel Spirit + same
    Insect; // same + immune to mental spells + immune to webs
    SlimeOrPlant; // same + same + immune to assassination
    StoneOrGolem; // same + same + immune to beams
    Special; // immune to assassination and lethal blow. Immune to simulacrum. Immune to webs.
    Vahnatai;
    Other;
}

enum AttackType {
    Strike;
    Claw;
    Bite;
    Slimes;
    Punches;
    Stings;
    Clubs;
    Burns;
    Harms;
    Stabs;
    Kicks;
}

enum StrategyType {
    Default;
    ArcherOrCaster;   
}

typedef Strategy = {
    type: StrategyType,
    persistentTarget: Bool
};

class CreatureData {
    public function new() {}
    
    public function clone():CreatureData {
        var cd = new CreatureData();
        for (field in CreatureData.getInstanceFields()) {
            cd.setField(field, this.field(field));
        }
        return cd;
    }

    public var name:String = "";
    public var default_script:String = "basicnpc";
    public var level = 2;
    public var hp_bonus = 0;
    public var sp_bonus = 0;
    private var special_abil = 0;
    // specialAbility() defined in kiss file
    public function specialAbility() {
        return Kiss.exp('(case special_abil
                                (0 None)
                                (1 (Melee Poison))
                                (2 (Ray CurseAndWeaken))
                                (3 (Ray TurnToStone))
                                (4 (Melee Slow))
                                (5 (Throw Web4))
                                (6 (Melee Disease))
                                (7 (Ray Charm))
                                (8 (Melee Sleep))
                                (9 (Ray Sleep))
                                (10 (Melee Paralyze))
                                (11 (Ray Paralyze))
                                (12 (Melee Acid))
                                (13 (Ray DrainSP))
                                (14 (Ray Confuse))
                                (15 (Ray Terrify))
                                (16 (Throw Rocks))
                                (17 (Breath Fire))
                                (18 (Breath Cold))
                                (19 (Breath Acid))
                                (20 (Melee Fire))
                                (21 (Melee Cold))
                                (22 (Melee DrainXP))
                                (23 (Melee ColdDrainXP))
                                (24 Invisible)
                                (26 (Radiate Fire))
                                (27 (Radiate Cold))
                                (28 (Radiate AntiMagic))
                                (29 SplitsWhenHit)
                                (30 (Ray Fire))
                                (32 (Ray MagicDamage))
                                (33 (Breath Darkness))
                                (34 (Throw Spines))
                                (35 ForceCage)
                                (36 (Melee Web))
                                (37 (Radiate Sleep))
                                (38 (Radiate Stink))
                                (39 (Radiate Blade))
                                (otherwise (throw "undefined special_abil")))');
    }

    private var default_attitude = 2;
    public function defaultAttitude() {
        return Attitude.createEnumIndex(default_attitude - 2);
    }

    private var species = 0;
    public function getSpecies() {
        return Species.createEnumIndex(species);
    }
    public var natural_armor = 0;
    public var attack_1 = 0;
    public var attack_2 = 0;
    public var attack_3 = 0;
    private var attack_1_type = 0;
    public function attack1Type() {
        return AttackType.createEnumIndex(attack_1_type);
    }
    private var attack_23_type = 0;
    public function attack23Type() {
        return AttackType.createEnumIndex(attack_23_type);
    }
    public var ap_bonus = 0;
    private var default_strategy = 0;
    public function defaultStrategy():Strategy {
        return {
            type: StrategyType.createEnumIndex(default_strategy % 10),
            persistentTarget: default_strategy >= 10
        };
    }

    private var default_aggression = 100;
    public function defaultAggression() {
        return default_aggression / 100.0;
    }
    private var default_courage = 100;
    public function defaultCourage() {
        return default_courage / 100.0;
    }
    public var which_sheet = 0;
    public var icon_adjust = 0;
    private var small_or_large_template = 0;
    public var which_sheet_upper = -1;
    public var summon_class = -1;
    private var what_stat_adjust:Array<Int> = [];
    private var amount_stat_adjust:Array<Int> = [];
    private var start_item:Array<Int> = [];
    private var start_item_chance:Array<Int> = [];
    private var immunities:Array<Int> = [];

    // TODO public functions that return and contextualize the array variables
}
