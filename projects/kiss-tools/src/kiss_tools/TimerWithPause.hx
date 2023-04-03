package kiss_tools;

import kiss.Prelude;
import kiss.List;
import haxe.Timer;

typedef WrappedTimer = {
    startTime:Float,
    duration:Float,
    t:Timer,
    f:Void->Void
}

@:build(kiss.Kiss.build())
class TimerWithPause {}
