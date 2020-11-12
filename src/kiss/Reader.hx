package kiss;

import haxe.ds.Option;
import kiss.Stream;

enum ReaderExp {
	Call(func:ReaderExp, args:Array<ReaderExp>); // (f a1 a2...)
	List(exps:Array<ReaderExp>); // [v1 v2 v3]
	Str(s:String); // "literal"
	Symbol(name:String); // s
	RawHaxe(code:String);
}

typedef ReadFunction = (Stream) -> Null<ReaderExp>;

class Reader {
	var readTable:Map<String, ReadFunction> = new Map();

	public function new() {
		readTable["("] = (stream) -> Call(assertRead(stream), readExpArray(stream, ")"));
		readTable["["] = (stream) -> List(readExpArray(stream, "]"));
		readTable["\""] = (stream) -> Str(stream.expect("closing \"", () -> stream.takeUntilAndDrop("\"")));
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
	}

	public function assertRead(stream:Stream):ReaderExp {
		var position = stream.position();
		return switch (read(stream)) {
			case Some(exp):
				exp;
			case None:
				throw "There were no expressions left in the stream at $position";
		};
	}

	public function read(stream:Stream):Option<ReaderExp> {
		stream.dropWhitespace();

		var readTableKeys = [for (key in readTable.keys()) key];
		readTableKeys.sort((a, b) -> b.length - a.length);

		for (key in readTableKeys) {
			switch (stream.peekChars(key.length)) {
				case Some(k) if (k == key):
					stream.dropString(key);
					var expOrNull = readTable[key](stream);
					return if (expOrNull != null) Some(expOrNull) else None;
				default:
			}
		}

		return Some(Symbol(stream.expect("a symbol name", () -> stream.takeUntilOneOf([")", "]", "/*", "\n", " "]))));
	}

	public function readExpArray(stream:Stream, end:String):Array<ReaderExp> {
		var array = [];
		while (stream.expect('$end to terminate list', () -> stream.peekChars(end.length)) != end) {
			stream.dropWhitespace();
			array.push(assertRead(stream));
		}
		stream.dropString(end);
		return array;
	}
}
