package nat;

import kiss.Prelude;

typedef EntryChecker = (Archive, Entry) -> Bool;
typedef EntryProcessor = (Archive, Entry) -> Void;

@:build(kiss.Kiss.build())
class System {}
