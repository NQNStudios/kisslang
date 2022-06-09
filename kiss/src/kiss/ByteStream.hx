package kiss;

import sys.io.File;
import haxe.io.Bytes;

class ByteStream {
    var bytes = Bytes.alloc(0);
    var position = 0;

    function new () {}

    public static function fromFile(file) {
        var s = new ByteStream();
        s.bytes = File.getBytes(file);
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
}
