package nat;

import kiss.Prelude;
import kiss.List;
import kiss.Operand;
import haxe.Constraints;
import uuid.Uuid;

enum CommandArgType {
    SelectedEntry;
    SelectedEntries(min:Null<Int>, max:Null<Int>);
    Text(maxLength:Null<Float>); // max length is a float so Math.POSITIVE_INFINITY can be used
    VarText(maxLength:Null<Float>);
    Number(min:Null<Float>, max:Null<Float>, inStepsOf:Null<Float>);
    OneEntry; // This constructor must be disambiguated from the typedef "Entry"
    Entries(min:Null<Int>, max:Null<Int>);
}

typedef CommandArg = {
    name:String,
    type:CommandArgType
};

typedef Command = {
    args:Array<CommandArg>,
    handler:Function
    // Command handlers need to return a ChangeSet
};

typedef ChangeSet = Array<Entry>;

@:build(kiss.Kiss.build())
class ArchiveController {}
