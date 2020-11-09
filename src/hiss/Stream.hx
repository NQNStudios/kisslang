package hiss;

import sys.io.File;
import haxe.ds.Option;

using StringTools;
using Lambda;

class Stream {
	var content:String;
	var file:String;
	var line:Int;
	var column:Int;

	public function new(file:String) {
		// Banish ye Windows line-endings
		content = File.getContent(file).replace('\r', '');

		this.file = file;
		line = 1;
		column = 1;
	}

	public function peekChars(chars:Int):Option<String> {
		if (content.length < chars)
			return None;
		return Some(content.substr(0, chars));
	}

	public function isEmpty() {
		return content.length == 0;
	}

	public function position() {
		return '$file:$line:$column';
	}

	/** Every drop call should end up calling dropChars() or the position tracker will be wrong. **/
	private function dropChars(count:Int) {
		for (idx in 0...count) {
			switch (content.charAt(idx)) {
				case "\n":
					line += 1;
					column = 1;
				default:
					column += 1;
			}
		}
		content = content.substr(count);
	}

	public function takeChars(count:Int):Option<String> {
		if (count > content.length)
			return None;
		var toReturn = content.substr(0, count);
		dropChars(count);
		return Some(toReturn);
	}

	public function dropString(s:String) {
		var toDrop = content.substr(0, s.length);
		if (toDrop != s) {
			throw 'Expected $s at ${position()}';
		}
		dropChars(s.length);
	}

	public function dropUntil(s:String) {
		dropChars(content.indexOf(s));
	}

	public function dropWhitespace() {
		var trimmed = content.ltrim();
		dropChars(content.length - trimmed.length);
	}

	public function takeUntilOneOf(terminators:Array<String>):Option<String> {
		var indices = [for (term in terminators) content.indexOf(term)].filter((idx) -> idx >= 0);
		if (indices.length == 0)
			return None;
		var firstIndex = Math.floor(indices.fold(Math.min, indices[0]));
		return takeChars(firstIndex);
	}

	public function takeUntilAndDrop(s:String):Option<String> {
		var idx = content.indexOf(s);

		if (idx < 0)
			return None;

		var toReturn = content.substr(0, idx);
		dropChars(toReturn.length + s.length);
		return Some(toReturn);
	}

	public function expect(whatToExpect:String, f:Void->Option<String>):String {
		var position = position();
		switch (f()) {
			case Some(s):
				return s;
			case None:
				throw 'Expected $whatToExpect at $position';
		}
	}
}
