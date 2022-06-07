package;

import sys.io.File;
import haxe.io.Bytes;
import flash.display.BitmapData;
import flixel.util.FlxColor;

typedef ByteStream = {
    bytes:Bytes,
    position:Int
};

class Bmp {
    static function getByteStream(file:String):ByteStream {
        return {
            bytes: File.getBytes(file),
            position:0
        };
    }

    static function readByte(bytes:ByteStream):Int {
        return bytes.bytes.get(bytes.position++);
    }

    static function readInt32(bytes:ByteStream):Int {
        var int = bytes.bytes.getInt32(bytes.position);
        bytes.position += 4;
        return int;
    }

    static function readUInt32(bytes:ByteStream):Int {
        var int = readInt32(bytes);
        return if (int < 0) cast (4294967296 + cast int) else int; 
    }

    static function readUInt16(bytes:ByteStream):Int {
        var int = bytes.bytes.getUInt16(bytes.position);
        bytes.position += 2;
        return int;
    }

    static function checkHeader(bytes:ByteStream) {
        // 42 4D
        if (readByte(bytes) != 66 || readByte(bytes) != 77)
            throw 'Bad bmp header!';
    }

    public static function loadBitmapData(bmpFile:String) {
        var stream = getByteStream(bmpFile);
        checkHeader(stream);
        
        var fileSize = readUInt32(stream);
        var fileReserved = readUInt32(stream);
        var fileOffBits = readUInt32(stream);

        var imgSize = readUInt32(stream);

        var imgWidth = readInt32(stream);
        var imgHeight = readInt32(stream);

        var planes = readUInt16(stream);
        var bitsPerPixel = readUInt16(stream);

        var compression = readUInt32(stream);
        var sizeImage = readUInt32(stream);

        var xPixelsPerMeter = readInt32(stream);
        var yPixelsPerMeter = readInt32(stream);

        var colorsUsed = readUInt32(stream);
        var colorsImportant = readUInt32(stream);

        var colors:Array<FlxColor> = [];

        for (c in 0...colorsUsed) {
            var blue = readByte(stream);
            var green = readByte(stream);
            var red = readByte(stream);
            var _ = readByte(stream);
            colors.push(FlxColor.fromRGB(red, green, blue));
        }

        // BMPs can be encoded upside-down when the height is negative
        var realHeight:Int = cast Math.abs(imgHeight);
        var data = new BitmapData(imgWidth, realHeight);
        var y = if (imgHeight > 0) 0 else realHeight - 1;
        var dy = if (imgHeight > 0) 1 else -1;
        var rowPadding:Int = cast (sizeImage - (realHeight * imgWidth)) / realHeight;
        for (_ in 0... realHeight) {
            for (x in 0... imgWidth) {
                var colorIdx = readByte(stream);
                data.setPixel(x, realHeight-1-y, colors[colorIdx]);
            }
            for (_ in 0... rowPadding) {
                readByte(stream);
            }

            y += dy;
        }

        return data;
    }
}