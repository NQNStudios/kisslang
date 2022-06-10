package kiss;

import sys.io.File;
import haxe.io.Bytes;

class ByteStream {
    var bytes = Bytes.alloc(0);
    var position = 0;
    var file = "";
    function new () {}

    public static function fromFile(file) {
        var s = new ByteStream();
        s.bytes = File.getBytes(file);
        s.file = file;
        return s;
    }

    public function readByte():Int {
        return bytes.get(position++);
    }

    public function readInt32():Int {
        var int = bytes.getInt32(position);
        position += 4;
        return int;
    }

    public function readUInt32():Int {
        var int = readInt32();
        return if (int < 0) cast (4294967296 + cast int) else int; 
    }

    public function readUInt16():Int {
        var int = bytes.getUInt16(position);
        position += 2;
        return int;
    }

    // Read a C-style 0-terminated ascii string
    public function readCString(maxLength = 0):String {
        var string = "";
        var pos = position;
        var _maxBytes = if (maxLength <= 0) bytes.length - position else maxLength; // TODO test this for off-by-one error
        for (idx in 0..._maxBytes) {
            var next = readByte();
            if (next == 0) {
                if (maxLength > 0)
                    paddingBytes(_maxBytes - idx);
                return string;
            }
            else string += String.fromCharCode(next);
        }
        if (maxLength <= 0) {
            throw 'C String starting at byte $pos in $file ends in unexpected EOF';
        } else {
            throw 'C String starting at byte $pos in $file is longer than $maxLength bytes: $string';
        }
    }

    public function skipZeros() {
        while (readByte() == 0) {}
        
        position--;
    }

    public function unknownBytes(num:Int) {
        trace('Warning: ignoring $num unknown bytes starting at $position in $file');
        paddingBytes(num);
    }

    public function paddingBytes(num) {
        for (_ in 0...num) readByte();
    }
}
