package kiss_flixel;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import flixel.addons.plugin.FlxMouseControl;
import flixel.util.FlxCollision;
import flash.display.BitmapData;

class KissExtendedSprite extends flixel.addons.display.FlxExtendedSprite {
    public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, SimpleGraphic);
	}

    var dragStartPos:FlxPoint = null;
    var mouseStartPos:FlxPoint = null;
    
    public var connectedSprites:Array<KissExtendedSprite> = [];
    var connectedSpritesStartPos:Array<FlxPoint> = [];

    function resetStartPos() {
        dragStartPos = new FlxPoint(x, y);
        connectedSpritesStartPos = [for (s in connectedSprites) new FlxPoint(s.x, s.y)];
        mouseStartPos = FlxG.mouse.getWorldPosition();
    }

    public override function startDrag() {
        super.startDrag();

        resetStartPos();
    }

    private var rotationPadding = new FlxPoint();
    public function getRotationPadding() {
        return rotationPadding.copyTo();
    }

    public override function loadRotatedGraphic(Graphic:FlxGraphicAsset, Rotations:Int = 16, Frame:Int = -1, AntiAliasing:Bool = false, AutoBuffer:Bool = false, ?Key:String) {
        var ow = frameWidth;
        var oh = frameHeight;
        var g = super.loadRotatedGraphic(Graphic, Rotations, Frame, AntiAliasing, AutoBuffer, Key);
        rotationPadding.set(frameWidth - ow, frameHeight - oh).scale(0.5);
        return g;
    }

    public override function isSimpleRender(?camera:FlxCamera) {
        return false;
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
                offset.rotate(new FlxPoint(0, 0), deg);
                s.x = x + offset.x;
                s.y = y + offset.y;
            }
        }
        _rot(this, deg);
        for (c in connectedSprites) {
            if (c != this) {
                _rot(c, deg);
            }
        }
        resetStartPos();
    }

    override function update(elapsed:Float) {
        #if debug
        // color = (mouseOver && pixelPerfect(_dragPixelPerfectAlpha)) ? FlxColor.LIME : FlxColor.WHITE;
        #end
        super.update(elapsed);
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

    #if FLX_MOUSE
    override function get_mouseOver() {
        var mouseOver = getScreenBounds(cameras[0]).containsPoint(FlxG.mouse.getScreenPosition(cameras[0]));
        
        return mouseOver;
    }

    function pixelPerfect(alpha) {
        return pixelPerfectPointCheck(Math.floor(FlxG.mouse.x), Math.floor(FlxG.mouse.y), this, alpha);
    }

    static function pixelPerfectPointCheck(PointX:Int, PointY:Int, Target:FlxSprite, AlphaTolerance:Int = 1):Bool
	{
		if (FlxG.renderTile)
		{
			Target.drawFrame();
		}

		// How deep is pointX/Y within the rect?
		var test:BitmapData = Target.framePixels;

		var pixelAlpha = FlxColor.fromInt(test.getPixel32(Math.floor(PointX - Target.x), Math.floor(PointY - Target.y))).alpha;

		if (FlxG.renderTile)
		{
			pixelAlpha = Std.int(pixelAlpha * Target.alpha);
		}

		// How deep is pointX/Y within the rect?
		return pixelAlpha >= AlphaTolerance;
	}
    
    override function checkForClick():Void
	{
		#if FLX_MOUSE
		if (mouseOver && FlxG.mouse.justPressed)
		{
			//	If we don't need a pixel perfect check, then don't bother running one! By this point we know the mouse is over the sprite already
			if (_clickPixelPerfect == false && _dragPixelPerfect == false)
			{
				FlxMouseControl.addToStack(this);
				return;
			}

			if (_clickPixelPerfect && pixelPerfect(_clickPixelPerfectAlpha))
			{
				FlxMouseControl.addToStack(this);
				return;
			}

			if (_dragPixelPerfect && pixelPerfect(_dragPixelPerfectAlpha))
			{
				FlxMouseControl.addToStack(this);
				return;
			}
		}
		#end
	}
    #end
}