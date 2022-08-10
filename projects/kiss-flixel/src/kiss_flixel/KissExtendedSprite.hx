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