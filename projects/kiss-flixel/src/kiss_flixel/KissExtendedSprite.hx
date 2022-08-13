package kiss_flixel;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;

class KissExtendedSprite extends flixel.addons.display.FlxExtendedSprite {
    public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, SimpleGraphic);
	}

    var dragStartPos:FlxPoint = null;
    var mouseStartPos:FlxPoint = null;
    
    public var connectedSprites:Array<KissExtendedSprite> = [];
    var connectedSpritesStartPos:Array<FlxPoint> = [];

    public override function startDrag() {
        super.startDrag();

        dragStartPos = new FlxPoint(x, y);
        connectedSpritesStartPos = [for (s in connectedSprites) new FlxPoint(s.x, s.y)];
        mouseStartPos = FlxG.mouse.getWorldPosition();
    }

    // Sleazy method just for Habit Puzzles
    public function rotate(deg:Float) {
        if (deg < 0) {
            deg += 360 * Math.ceil(Math.abs(deg / 360));
        }
        function _rot(s:KissExtendedSprite, deg) {
            var angle = (s.angle + deg) % 360;
            s.angle = angle;
            if (s != this) {
                var thisCenter = new FlxPoint(x + origin.x, y + origin.y);
                var sCenter = new FlxPoint(s.x + s.origin.x, s.y + s.origin.y);
                var offset = sCenter.subtractPoint(thisCenter);
                s.origin.subtractPoint(offset);
                //var newPosition = s.getScreenPosition(s.cameras[0]);
            }
        }
        _rot(this, deg);
        for (c in connectedSprites) {
            if (c != this) {
                _rot(c, deg);
            }
        }
    }

    override function updateDrag() {
        var mouseTotalMovement = FlxG.mouse.getWorldPosition().subtractPoint(mouseStartPos);
        var nextPos = dragStartPos.copyTo().addPoint(mouseTotalMovement);
        x = nextPos.x;
        y = nextPos.y;
        for (i in 0...connectedSprites.length) {
            var sprite = connectedSprites[i];
            var startPos = connectedSpritesStartPos[i];
            var nextPos = startPos.copyTo().addPoint(mouseTotalMovement);
            sprite.x = nextPos.x;
            sprite.y = nextPos.y;
        }
    }
}