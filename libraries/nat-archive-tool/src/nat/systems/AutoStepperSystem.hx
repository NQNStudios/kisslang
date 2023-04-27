package nat.systems;

import kiss.Prelude;
import kiss.List;
import nat.System;
import haxe.Json;
#if target.threaded
import sys.thread.Thread;
#end

using haxe.io.Path;

/**
 * Base System that processes Entries based on whether they have file attachments
 * which match a given set of extensions
 */
@:build(kiss.Kiss.build())
class AutoStepperSystem extends AttachmentSystem {}
