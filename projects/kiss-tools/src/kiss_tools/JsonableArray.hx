package kiss_tools;

import kiss.Prelude;
import kiss.List;
import kiss_tools.JsonMap;
import haxe.Json;
import haxe.DynamicAccess;

@:build(kiss.Kiss.build())
class JsonableArray<T:Jsonable<T>> {}
