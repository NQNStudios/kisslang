package;

import kiss.Prelude;
import kiss.List;
import kiss.Stream;
import sys.io.File;

enum EntryType {
    Daily(daysOfWeek:Array<Int>);
    Bonus;
    Todo;
}

typedef EntryLabel = {
    label:String,
    points:Int
};

typedef Entry = {
    type: EntryType,
    labels: Array<EntryLabel>,
    doneToday: Bool
};

typedef RewardFile = {
    path: String,
    startingPoints: Int
};

@:build(kiss.Kiss.build())
class HabitModel {}
