package nat;

import kiss.Prelude;

typedef EntryChecker = (Archive, Entry) -> Bool;
typedef EntryProcessor = (Archive, Entry) -> Dynamic; // Whatever value is returned will be dropped, but this is easier than requiring ->:Void

@:build(kiss.Kiss.build())
class System {}
