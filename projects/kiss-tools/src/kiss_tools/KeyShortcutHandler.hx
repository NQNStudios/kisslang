package kiss_tools;

import kiss.Prelude;
import kiss.Stream;
import kiss.List;

typedef PrefixMap<T> = Map<String, ShortcutKey<T>>;
typedef PrefixMapHandler<T> = (Map<String, ShortcutKey<T>>, Map<String,String>) -> Void;
typedef ItemHandler<T> = (T) -> Void;
typedef FinishHandler = () -> Void;
typedef BadKeyHandler<T> = (String, PrefixMap<T>) -> Void;
typedef BadShortcutHandler<T> = (String, ShortcutKey<T>) -> Void;

enum ShortcutKey<T> {
    Cancel(key:String);
    Final(item:T);
    Prefix(keys:PrefixMap<T>);
}

@:build(kiss.Kiss.build())
class KeyShortcutHandler<T> {}
