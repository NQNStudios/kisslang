package;

import kiss.ByteStream;
import flash.display.BitmapData;
import flixel.util.FlxColor;

class Bmp {
    

    static function checkHeader(bytes:ByteStream) {
        // 42 4D
        if (bytes.readByte() != 66 || bytes.readByte() != 77)
            throw 'Bad bmp header!';
    }

    public static function loadBitmapData(bmpFile:String) {
        var stream = ByteStream.fromFile(bmpFile);
        checkHeader(stream);
        
        var fileSize = stream.readUInt32();
        var fileReserved = stream.readUInt32();
        var fileOffBits = stream.readUInt32();

        var imgSize = stream.readUInt32();

        var imgWidth = stream.readInt32();
        var imgHeight = stream.readInt32();

        var planes = stream.readUInt16();
        var bitsPerPixel = stream.readUInt16();

        var compression = stream.readUInt32();
        var sizeImage = stream.readUInt32();

        var xPixelsPerMeter = stream.readInt32();
        var yPixelsPerMeter = stream.readInt32();

        var colorsUsed = stream.readUInt32();
        var colorsImportant = stream.readUInt32();

        var colors:Array<FlxColor> = [];

        for (c in 0...colorsUsed) {
            var blue = stream.readByte();
            var green = stream.readByte();
            var red = stream.readByte();
            var _ = stream.readByte();
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
                var colorIdx = stream.readByte();
                data.setPixel(x, realHeight-1-y, colors[colorIdx]);
            }
            for (_ in 0... rowPadding) {
                stream.readByte();
            }

            y += dy;
        }

        return data;
    }
}