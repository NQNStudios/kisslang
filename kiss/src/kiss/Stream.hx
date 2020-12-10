package kiss;

import sys.io.File;
import haxe.ds.Option;

using StringTools;
using Lambda;

typedef Position = {
    file:String,
    line:Int,
    column:Int,
    absoluteChar:Int
};

class Stream {
    public var content(default, null):String;

    var file:String;
    var line:Int;
    var column:Int;
    var absoluteChar:Int;

    var absolutePerNewline = 1;

    public function new(file:String) {
        // Banish ye Windows line-endings
        content = File.getContent(file);

        if (content.indexOf('\r') >= 0) {
            absolutePerNewline = 2;
            content = content.replace('\r', '');
        }
        // Life is easier with a trailing newline
        if (content.charAt(content.length - 1) != "\n")
            content += "\n";

        this.file = file;
        line = 1;
        column = 1;
        absoluteChar = 0;
    }

    public function peekChars(chars:Int):Option<String> {
        if (content.length < chars)
            return None;
        return Some(content.substr(0, chars));
    }

    public function isEmpty() {
        return content.length == 0;
    }

    public function position():Position {
        return {
            file: file,
            line: line,
            column: column,
            absoluteChar: absoluteChar
        };
    }

    public static function toPrint(p:Position) {
        return '${p.file}:${p.line}:${p.column}';
    }

    public function startsWith(s:String) {
        return switch (peekChars(s.length)) {
            case Some(s1) if (s == s1): true;
            default: false;
        };
    }

    var lineLengths = [];

    /** Every drop call should end up calling dropChars() or the position tracker will be wrong. **/
    private function dropChars(count:Int) {
        for (idx in 0...count) {
            switch (content.charAt(idx)) {
                case "\n":
                    absoluteChar += absolutePerNewline;
                    line += 1;
                    lineLengths.push(column);
                    column = 1;
                default:
                    absoluteChar += 1;
                    column += 1;
            }
        }
        content = content.substr(count);
    }

    public function putBackString(s:String) {
        var idx = s.length - 1;
        while (idx >= 0) {
            absoluteChar -= 1;
            switch (s.charAt(idx)) {
                case "\n":
                    line -= 1;
                    column = lineLengths.pop();
                default:
                    column -= 1;
            }
            --idx;
        }
        content = s + content;
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

    public function takeLine():Option<String> {
        return takeUntilAndDrop("\n");
    }

    public function expect(whatToExpect:String, f:Void->Option<String>):String {
        var position = position();
        switch (f()) {
            case Some(s):
                return s;
            default:
                throw 'Expected $whatToExpect at $position';
        }
    }
}
