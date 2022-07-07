package nat.systems;

import kiss.Prelude;
import kiss.List;
import nat.System;
#if target.threaded
import sys.thread.Thread;
#end

@:build(kiss.Kiss.build())
class DLSystem extends System {}
