package nat;

import kiss.Prelude;
import kiss.List;
import kiss.Operand;

import haxe.Constraints;

enum CommandArgument {
    SelectedEntry;
    SelectedEntries(min:Null<Int>, max:Null<Int>);
    Text(minLength:Null<Int>, maxLength:Null<Int>);
    Number(min:Null<Float>, max:Null<Float>, inStepsOf:Null<Float>);
    Entry;
    Entries(min:Null<Int>, max:Null<Int>);
}

typedef Command = {
    args:Array<CommandArgument>,
    handler:Function
};

typedef ChangeSet = Array<Entry>;

@:build(kiss.Kiss.build())
class ArchiveController {}
