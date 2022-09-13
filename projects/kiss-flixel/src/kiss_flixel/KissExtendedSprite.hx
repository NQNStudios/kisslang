package kiss_flixel;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import flixel.addons.plugin.FlxMouseControl;
import flixel.util.FlxCollision;
import flash.display.BitmapData;
import kiss_flixel.DragToSelectPlugin;

class KissExtendedSprite extends flixel.addons.display.FlxExtendedSprite {
    public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, SimpleGraphic);
	}

    var dragStartPos:FlxPoint = null;
    var mouseStartPos:FlxPoint = null;
    
    public var connectedSprites:Array<KissExtendedSprite> = [];
    public function connectedAndSelectedSprites() {
        var l = connectedSprites;
        var map = [for (s in l) s => true];
        if (_dragToSelectEnabled) {
            var plugin = FlxG.plugins.get(DragToSelectPlugin); 
            for (s in plugin.selectedSprites()) {
                map[s] = true;
                for (c in s.connectedSprites) {
                    map[c] = true;
                }
            }
        }
        // Remove duplicates and return
        l = [for (s => bool in map) s];
        return l;
    }
    var connectedSpritesStartPos:Array<FlxPoint> = [];

    function resetStartPos() {
        dragStartPos = new FlxPoint(x, y);
        connectedSpritesStartPos = [for (s in connectedAndSelectedSprites()) new FlxPoint(s.x, s.y)];
        mouseStartPos = FlxG.mouse.getWorldPosition();
    }

    public override function startDrag() {
        super.startDrag();

        if (_dragToSelectEnabled) {
            var plugin = FlxG.plugins.get(DragToSelectPlugin); 
            if (plugin.selectedSprites().indexOf(this) == -1)
                plugin.deselectSprites();
        }

        resetStartPos();
    }

    public override function stopDrag() {
        super.stopDrag();
    }

    private var rotationPadding = new FlxPoint();
    public function getRotationPadding() {
        return rotationPadding.copyTo();
    }

    public override function loadRotatedGraphic(Graphic:FlxGraphicAsset, Rotations:Int = 16, Frame:Int = -1, AntiAliasing:Bool = false, AutoBuffer:Bool = false, ?Key:String) {
        var ow = frameWidth;
        var oh = frameHeight;
        var g = super.loadRotatedGraphic(Graphic, Rotations, Frame, AntiAliasing, AutoBuffer, Key);
        if (ow != frameWidth || oh != frameHeight) {
            rotationPadding.set(frameWidth - ow, frameHeight - oh).scale(0.5);
        }
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
                s.x = thisCenter.x + offset.x - s.origin.x;
                s.y = thisCenter.y + offset.y - s.origin.y;
            }
        }
        _rot(this, deg);
        for (c in connectedAndSelectedSprites()) {
            if (c != this) {
                _rot(c, deg);
            }
        }
        resetStartPos();
    }

    var _dragToSelectEnabled = false;
    public var onSelected:Void->Void = null;
    public var onDeselected:Void->Void;
    public function enableDragToSelect(?onSelected:Void->Void, ?onDeselected:Void->Void, ?state:FlxState, ?camera:FlxCamera) {
        this.onSelected = onSelected;
        this.onDeselected = onDeselected;
        var plugin = FlxG.plugins.get(DragToSelectPlugin); 
        if (plugin == null) {
            plugin = new DragToSelectPlugin();
            FlxG.plugins.add(plugin);
        }
        plugin.enableSprite(this, state, camera);
        _dragToSelectEnabled = true;
    }
    public function disableDragToSelect(?state:FlxState) {
        var plugin = FlxG.plugins.get(DragToSelectPlugin); 
        plugin.disableSprite(this, state);
        _dragToSelectEnabled = false;
    }

    public override function destroy() {
        if (_dragToSelectEnabled)
            disableDragToSelect();
        super.destroy();
    }

    public override function update(elapsed:Float) {
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
        var l = connectedAndSelectedSprites();
        for (i in 0...l.length) {
            var sprite = l[i];
            var startPos = connectedSpritesStartPos[i];
            var nextPos = startPos.copyTo().addPoint(mouseTotalMovement);
            sprite.x = nextPos.x;
            sprite.y = nextPos.y;
        }
    }


    public function pixelPerfectDrag() {
        return _dragPixelPerfect;
    }

    public function pixelPerfectAlpha() {
        return _dragPixelPerfectAlpha;
    }

    function thisCamera() {
        if (cameras != null && cameras.length > 0)
            return cameras[0];
        return FlxG.camera;
    }



    #if FLX_MOUSE
    override function get_mouseOver() {
        var mouseOver = getScreenBounds(thisCamera()).containsPoint(FlxG.mouse.getScreenPosition(thisCamera()));
        
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