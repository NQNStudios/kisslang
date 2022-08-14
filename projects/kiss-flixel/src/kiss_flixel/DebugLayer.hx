package kiss_flixel;

import kiss.Prelude;
import kiss.List;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxColor;
using flixel.util.FlxSpriteUtil;
using kiss_flixel.DebugLayer;

@:build(kiss.Kiss.build())
class DebugLayer extends FlxTypedGroup<FlxSprite> {
    public function drawRect(X:Float, Y:Float, Width:Float, Height:Float, FillColor:FlxColor = FlxColor.WHITE, ?lineStyle:Null<LineStyle>, ?drawStyle:Null<DrawStyle>):FlxSprite {
        var thickness = 1.0;
        if (lineStyle != null) {
            thickness = lineStyle.thickness;
        }
        
        var s = new FlxSprite(X-thickness/2, Y-thickness/2);

        // TODO test where thickness appears - is it center-out from the given border?
        s.mg(Width + thickness, Height + thickness);
        s.drawRect(thickness/2, thickness/2, Width, Height, FillColor, lineStyle, drawStyle);
        add(s);
        return s;
    }

    public static function mg(s:FlxSprite, Width:Float, Height:Float):FlxSprite {
        return s.makeGraphic(Math.ceil(Width), Math.ceil(Height), FlxColor.TRANSPARENT, true);
    }
}
