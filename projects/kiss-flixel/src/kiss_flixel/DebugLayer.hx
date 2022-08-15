package kiss_flixel;

import kiss.Prelude;
import kiss.List;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.group.FlxGroup;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxColor;
using flixel.util.FlxSpriteUtil;
using kiss_flixel.DebugLayer;

@:build(kiss.Kiss.build())
class DebugLayer extends FlxTypedGroup<FlxSprite> {
    public function drawRect(X:Float, Y:Float, Width:Float, Height:Float, outlineColor:FlxColor = FlxColor.WHITE, thickness = 1.0):FlxSprite {
        thickness /= cameras[0].zoom;
        
        var s = new FlxSprite(X-thickness/2, Y-thickness/2);

        // TODO test where thickness appears - is it center-out from the given border?
        s.mg(Width + thickness, Height + thickness);
        s.drawRect(thickness/2, thickness/2, Width, Height, FlxColor.TRANSPARENT, {color: outlineColor, thickness: thickness});
        add(s);
        return s;
    }

    public function drawFlxRect(rect:FlxRect, outlineColor:FlxColor = FlxColor.WHITE, thickness = 1.0):FlxSprite {
        return drawRect(rect.x, rect.y, rect.width, rect.height, outlineColor, thickness);
    }

    public function drawCircle(x:Float, y:Float, radius: Float, color = FlxColor.WHITE, thickness = 1.0):FlxSprite {
        thickness /= cameras[0].zoom;
        
        var s = new FlxSprite(x - radius - thickness/2, y - radius - thickness/2);
        s.mg(2 * (radius + thickness), 2 * (radius + thickness));
        s.drawCircle(s.width / 2, s.height / 2, FlxColor.TRANSPARENT, {color:color, thickness:thickness});
        add(s);
        return s;
    }

    public static function mg(s:FlxSprite, Width:Float, Height:Float):FlxSprite {
        return s.makeGraphic(Math.ceil(Width), Math.ceil(Height), FlxColor.TRANSPARENT, true);
    }

    public override function clear() {
        forEach((s)->{s.destroy();});
        super.clear();
    }
}
