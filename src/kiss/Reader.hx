package kiss;

import haxe.ds.Option;
import kiss.Stream;

enum ReaderExp {
    CallExp(func:ReaderExp, args:Array<ReaderExp>); // (f a1 a2...)
    ListExp(exps:Array<ReaderExp>); // [v1 v2 v3]
    StrExp(s:String); // "literal"
    Symbol(name:String); // s
    RawHaxe(code:String);
}

typedef ReadFunction = (Stream) -> Null<ReaderExp>;

class Reader {
    // The built-in readtable
    public static function builtins() {
        var readTable:Map<String, ReadFunction> = [];

        readTable["("] = (stream) -> CallExp(assertRead(stream, readTable), readExpArray(stream, ")", readTable));
        readTable["["] = (stream) -> ListExp(readExpArray(stream, "]", readTable));
        readTable["\""] = (stream) -> StrExp(stream.expect("closing \"", () -> stream.takeUntilAndDrop("\"")));
        readTable["/*"] = (stream) -> {
            stream.dropUntil("*/");
            stream.dropString("*/");
            null;
        };
        readTable["//"] = (stream) -> {
            stream.dropUntil("\n");
            null;
        };
        readTable["#|"] = (stream) -> RawHaxe(stream.expect("closing |", () -> stream.takeUntilAndDrop("|#")));

        return readTable;
    }

    public static function assertRead(stream:Stream, readTable:Map<String, ReadFunction>):ReaderExp {
        var position = stream.position();
        return switch (read(stream, readTable)) {
            case Some(exp):
                exp;
            case None:
                throw 'There were no expressions left in the stream at $position';
        };
    }

    public static function read(stream:Stream, readTable:Map<String, ReadFunction>):Option<ReaderExp> {
        stream.dropWhitespace();

        if (stream.isEmpty())
            return None;

        var readTableKeys = [for (key in readTable.keys()) key];
        readTableKeys.sort((a, b) -> b.length - a.length);

        for (key in readTableKeys) {
            switch (stream.peekChars(key.length)) {
                case Some(k) if (k == key):
                    stream.dropString(key);
                    var expOrNull = readTable[key](stream);
                    return if (expOrNull != null) Some(expOrNull) else read(stream, readTable);
                default:
            }
        }

        return Some(Symbol(stream.expect("a symbol name", () -> stream.takeUntilOneOf([")", "]", "/*", "\n", " "]))));
    }

    public static function readExpArray(stream:Stream, end:String, readTable:Map<String, ReadFunction>):Array<ReaderExp> {
        var array = [];
        while (stream.expect('$end to terminate list', () -> stream.peekChars(end.length)) != end) {
            stream.dropWhitespace();
            array.push(assertRead(stream, readTable));
        }
        stream.dropString(end);
        return array;
    }
}
