package sched;

import kiss.Kiss;
import kiss.Prelude;

enum AMPM {
    AM;
    PM;
}

enum Time {
    Time(hour:Int, minute:Int, ampm:AMPM);
}

typedef ScheduleEntry = {
    start:Time,
    text:String
}

typedef Schedule = Array<ScheduleEntry>;

@:build(kiss.Kiss.build())
class Main {}
