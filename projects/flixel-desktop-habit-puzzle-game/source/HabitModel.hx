package;

import kiss.Prelude;
import kiss.List;
import kiss.Stream;
import sys.io.File;
import datetime.DateTime;
import datetime.DateTimeInterval;
import haxe.ds.Option;
using StringTools;

enum EntryType {
    Daily(daysOfWeek:Array<Int>, lastDayDone:String);
    Interval(days:Int, lastDayDone:String);
    // -1 represents the last day of the month, and so on
    Monthly(daysOfMonth:Array<Int>, lastDayDone:String);
    Bonus;
    Todo;
}

typedef EntryLabel = {
    label:String,
    points:Int
};

typedef RewardFile = {
    path: String,
    startingPoints: Int,
    puzzleWidth: Int,
    puzzleHeight: Int,
    piecesPerPoint: Int,
    skipped: Bool

};

typedef Puzzle = {
    path:Null<String>,
    index:Int,
    outOf:Int
}

@:build(kiss.Kiss.build())
class HabitModel {}
