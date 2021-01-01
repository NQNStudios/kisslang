package kiss;

import haxe.ds.Option;
import kiss.Stream;
import kiss.Kiss;

using kiss.Reader;

typedef ReaderExp = {
    pos:Position,
    def:ReaderExpDef
};

class UnmatchedBracketSignal {
    public var type:String;
    public var position:Stream.Position;

    public function new(type, position) {
        this.type = type;
        this.position = position;
    }
}

enum ReaderExpDef {
    CallExp(func:ReaderExp, args:Array<ReaderExp>); // (f a1 a2...)
    ListExp(exps:Array<ReaderExp>); // [v1 v2 v3]
    StrExp(s:String); // "literal"
    Symbol(name:String); // s
    RawHaxe(code:String); // #| haxeCode() |#
    TypedExp(path:String, exp:ReaderExp); // :type [exp]
    MetaExp(meta:String, exp:ReaderExp); // &meta [exp]
    FieldExp(field:String, exp:ReaderExp); // .field [exp]
    KeyValueExp(key:ReaderExp, value:ReaderExp); // =>key value
    Quasiquote(exp:ReaderExp); // `[exp]
    Unquote(exp:ReaderExp); // ,[exp]
    UnquoteList(exp:ReaderExp); // ,@[exp]
}

typedef ReadFunction = (Stream, KissState) -> Null<ReaderExpDef>;
typedef ReadTable = Map<String, ReadFunction>;

class Reader {
    // The built-in readtable
    public static function builtins() {
        var readTable:ReadTable = [];

        readTable["("] = (stream, k) -> CallExp(assertRead(stream, k), readExpArray(stream, ")", k));
        readTable["["] = (stream, k) -> ListExp(readExpArray(stream, "]", k));
        readTable["\""] = (stream, k) -> StrExp(stream.expect("closing \"", () -> stream.takeUntilAndDrop("\"")));
        readTable["/*"] = (stream, k) -> {
            stream.takeUntilAndDrop("*/");
            null;
        };
        readTable["//"] = (stream, k) -> {
            stream.takeUntilAndDrop("\n");
            null;
        };
        readTable["#|"] = (stream, k) -> RawHaxe(stream.expect("closing |#", () -> stream.takeUntilAndDrop("|#")));

        readTable[":"] = (stream, k) -> TypedExp(nextToken(stream, "a type path"), assertRead(stream, k));

        readTable["&"] = (stream, k) -> MetaExp(nextToken(stream, "a meta symbol like mut, optional, rest"), assertRead(stream, k));

        readTable["!"] = (stream:Stream, k) -> CallExp(Symbol("not").withPos(stream.position()), [assertRead(stream, k)]);

        // Helpful for defining predicates to pass to Haxe functions:
        readTable["?"] = (stream:Stream, k) -> CallExp(Symbol("Prelude.truthy").withPos(stream.position()), [assertRead(stream, k)]);

        // Lets you dot-access a function result without binding it to a name
        readTable["."] = (stream, k) -> FieldExp(nextToken(stream, "a field name"), assertRead(stream, k));

        // Lets you construct key-value pairs for map literals or for-loops
        readTable["=>"] = (stream, k) -> KeyValueExp(assertRead(stream, k), assertRead(stream, k));

        readTable[")"] = (stream, k) -> {
            stream.putBackString(")");
            throw new UnmatchedBracketSignal(")", stream.position());
        };
        readTable["]"] = (stream, k) -> {
            stream.putBackString("]");
            throw new UnmatchedBracketSignal("]", stream.position());
        };

        readTable["`"] = (stream, k) -> Quasiquote(assertRead(stream, k));
        readTable[","] = (stream, k) -> Unquote(assertRead(stream, k));
        readTable[",@"] = (stream, k) -> UnquoteList(assertRead(stream, k));

        // Because macro keys are sorted by length and peekChars(0) returns "", this will be used as the default reader macro:
        readTable[""] = (stream, k) -> Symbol(nextToken(stream, "a symbol name"));

        return readTable;
    }

    public static final terminators = [")", "]", "/*", "\n", " "];

    public static function nextToken(stream:Stream, expect:String) {
        var tok = stream.expect(expect, () -> stream.takeUntilOneOf(terminators));
        if (tok.length == 0) {
            throw 'Expected token $expect at ${stream.position()}';
        }
        return tok;
    }

    public static function assertRead(stream:Stream, k:KissState):ReaderExp {
        var position = stream.position();
        return switch (read(stream, k)) {
            case Some(exp):
                exp;
            case None:
                throw 'There were no expressions left in the stream at $position';
        };
    }

    static function chooseReadFunction(stream:Stream, readTable:ReadTable):Null<ReadFunction> {
        var readTableKeys = [for (key in readTable.keys()) key];
        readTableKeys.sort((a, b) -> b.length - a.length);

        for (key in readTableKeys) {
            switch (stream.peekChars(key.length)) {
                case Some(ky) if (ky == key):
                    stream.dropString(key);
                    return readTable[key];
                default:
            }
        }

        return null;
    }

    public static function read(stream:Stream, k:KissState):Option<ReaderExp> {
        var readTable = k.readTable;
        stream.dropWhitespace();

        if (stream.isEmpty())
            return None;

        var position = stream.position();

        var readFunction = null;
        if (stream.startOfLine)
            readFunction = chooseReadFunction(stream, k.startOfLineReadTable);
        if (readFunction != null)
            stream.startOfLine = false;
        else
            readFunction = chooseReadFunction(stream, k.readTable);
        if (readFunction == null)
            throw 'No macro to read next expression';

        var expOrNull = readFunction(stream, k);
        return if (expOrNull != null) {
            Some(expOrNull.withPos(position));
        } else {
            read(stream, k);
        }
    }

    public static function readExpArray(stream:Stream, end:String, k:KissState):Array<ReaderExp> {
        var array = [];
        while (!stream.startsWith(end)) {
            stream.dropWhitespace();
            if (!stream.startsWith(end)) {
                try {
                    array.push(assertRead(stream, k));
                } catch (s:UnmatchedBracketSignal) {
                    if (s.type == end)
                        break;
                    else
                        throw s;
                }
            }
        }
        stream.dropString(end);
        return array;
    }

    /**
        Read all the expressions in the given stream, processing them one by one while reading.
        They can't be read all at once because some expressions change the Readtable state
    **/
    public static function readAndProcess(stream:Stream, k:KissState, process:(ReaderExp) -> Void) {
        while (true) {
            stream.dropWhitespace();
            if (stream.isEmpty())
                break;
            var position = stream.position();
            var nextExp = Reader.read(stream, k);
            // The last expression might be a comment, in which case None will be returned
            switch (nextExp) {
                case Some(nextExp):
                    process(nextExp);
                case None:
                    stream.dropWhitespace(); // If there was a comment, drop whitespace that comes after
            }
        }
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
            case FieldExp(field, exp):
                '.$field ${exp.def.toString()}';
            case KeyValueExp(keyExp, valueExp):
                '=>${keyExp.def.toString()} ${valueExp.def.toString()}';
            case Quasiquote(exp):
                '`${exp.def.toString()}';
            case Unquote(exp):
                ',${exp.def.toString()}';
            case UnquoteList(exp):
                ',@${exp.def.toString()}';
        }
    }
}
