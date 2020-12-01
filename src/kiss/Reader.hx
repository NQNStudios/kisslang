package kiss;

import haxe.ds.Option;
import kiss.Stream;

using kiss.Reader;

typedef ReaderExp = {
    pos:Position,
    def:ReaderExpDef
};

enum ReaderExpDef {
    CallExp(func:ReaderExp, args:Array<ReaderExp>); // (f a1 a2...)
    ListExp(exps:Array<ReaderExp>); // [v1 v2 v3]
    StrExp(s:String); // "literal"
    Symbol(name:String); // s
    RawHaxe(code:String); // #| haxeCode() |#
    TypedExp(path:String, exp:ReaderExp); // :type [exp]
    MetaExp(meta:String, exp:ReaderExp); // &meta [exp]
}

typedef ReadFunction = (Stream) -> Null<ReaderExpDef>;

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
        readTable["#|"] = (stream) -> RawHaxe(stream.expect("closing |#", () -> stream.takeUntilAndDrop("|#")));
        // For defmacrofuns, unquoting with , is syntactic sugar for calling a Quote (Void->T)
        readTable[","] = (stream) -> CallExp(assertRead(stream, readTable), []);
        // If/when proper defmacro is added, reading every Unquote directly as a CallExp won't work anymore

        readTable[":"] = (stream) -> TypedExp(nextToken(stream, "a type path"), assertRead(stream, readTable));

        readTable["&"] = (stream) -> MetaExp(nextToken(stream, "a meta symbol like mut, optional, rest"), assertRead(stream, readTable));

        readTable["!"] = (stream:Stream) -> CallExp(Symbol("not").withPos(stream.position()), [assertRead(stream, readTable)]);

        // Helpful for defining predicates to pass to Haxe functions:
        readTable["?"] = (stream:Stream) -> CallExp(Symbol("Prelude.truthy").withPos(stream.position()), [assertRead(stream, readTable)]);

        // Because macro keys are sorted by length and peekChars(0) returns "", this will be used as the default reader macro:
        readTable[""] = (stream) -> Symbol(nextToken(stream, "a symbol name"));

        return readTable;
    }

    public static final terminators = [")", "]", "/*", "\n", " "];

    static function nextToken(stream:Stream, expect:String) {
        return stream.expect(expect, () -> stream.takeUntilOneOf(terminators));
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

        var position = stream.position();
        var readTableKeys = [for (key in readTable.keys()) key];
        readTableKeys.sort((a, b) -> b.length - a.length);

        for (key in readTableKeys) {
            switch (stream.peekChars(key.length)) {
                case Some(k) if (k == key):
                    stream.dropString(key);
                    var expOrNull = readTable[key](stream);
                    return if (expOrNull != null) {
                        Some(expOrNull.withPos(position));
                    } else {
                        read(stream, readTable);
                    }
                default:
            }
        }

        throw 'No macro to read next expression';
    }

    public static function readExpArray(stream:Stream, end:String, readTable:Map<String, ReadFunction>):Array<ReaderExp> {
        var array = [];
        while (!stream.startsWith(end)) {
            stream.dropWhitespace();
            if (!stream.startsWith(end))
                array.push(assertRead(stream, readTable));
        }
        stream.dropString(end);
        return array;
    }

    public static function withPos(def:ReaderExpDef, pos:Position) {
        return {
            pos: pos,
            def: def
        };
    }

    public static function withPosOf(def:ReaderExpDef, exp:ReaderExp) {
        return {
            pos: exp.pos,
            def: def
        };
    }

    public static function toString(exp:ReaderExpDef) {
        return switch (exp) {
            case CallExp(func, args):
                // (f a1 a2...)
                var str = '(' + func.def.toString();
                if (args.length > 0)
                    str += " ";
                str += [
                    for (arg in args) {
                        arg.def.toString();
                    }
                ].join(" ");
                str += ')';
                str;
            case ListExp(exps):
                // [v1 v2 v3]
                var str = '[';
                str += [
                    for (exp in exps) {
                        exp.def.toString();
                    }
                ].join(" ");
                str += ']';
                str;
            case StrExp(s):
                // "literal"
                '"$s"';
            case Symbol(name):
                // s
                name;
            case RawHaxe(code):
                // #| haxeCode() |#
                '#| $code |#';
            case TypedExp(path, exp):
                // :type [exp]
                ':$path ${exp.def.toString()}';
            case MetaExp(meta, exp):
                // &meta
                '&$meta ${exp.def.toString()}';
        }
    }
}
