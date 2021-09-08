package nat.systems;

import kiss.Prelude;
import kiss.List;
import nat.System;
import haxe.Json;

/**
 * Base System that processes Entries using the HTTP API for any wiki built with MediaWiki
 */
@:build(kiss.Kiss.build())
class MediaWikiSystem extends System {}
