package nat.systems;

import kiss.Prelude;
import kiss.List;
import nat.System;
import nat.components.*;
import haxe.DynamicAccess;
import haxe.ds.Option;

typedef PlaygroundEntryProcessor = (Archive, Entry, Position, ?ArchiveUI) -> Dynamic; // Whatever value is returned will be dropped, but this is easier than requiring ->:Void
typedef PlaygroundConnectionProcessor = (Archive, Entry, Position, Entry, Position, ?ArchiveUI) -> Dynamic; // Whatever value is returned will be dropped, but this is easier than requiring ->:Void

/**
 * Base class for Systems that process Entries in a playground view and displays them in an interactive form
 * (EntrySpriteSystem, for example)
 */
@:build(kiss.Kiss.build())
class PlaygroundSystem<EntryRep> extends System {}
