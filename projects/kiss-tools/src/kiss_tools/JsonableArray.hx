package kiss_tools;

import kiss.Prelude;
import kiss.List;

@:build(kiss.Kiss.build())
class JsonableArray<T:Jsonable<T>> {}
