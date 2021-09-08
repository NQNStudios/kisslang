package nat.systems;

import nat.systems.MediaWikiSystem;
import kiss.Prelude;

using haxe.io.Path;
using StringTools;

/**
 * System which downloads and attaches images from Wikipedia pages that match Entries' names. 
 */
@:build(kiss.Kiss.build())
class WikipediaImageSystem extends MediaWikiSystem {}
