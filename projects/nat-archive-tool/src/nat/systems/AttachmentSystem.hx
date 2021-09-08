package nat.systems;

import kiss.Prelude;
import kiss.List;
import nat.System;
import haxe.Json;

using haxe.io.Path;

typedef AttachmentProcessor = (Archive, Entry, Array<String>) -> Dynamic;

/**
 * Base System that processes Entries based on whether they have file attachments
 * which match a given set of extensions
 */
@:build(kiss.Kiss.build())
class AttachmentSystem extends System {}
