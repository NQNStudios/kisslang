package kiss_flixel;

import flixel.FlxG;
import flixel.addons.plugin.FlxMouseControl;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxBasic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import openfl.geom.Rectangle;
import flixel.util.FlxColor;

typedef DragState = {
    camera:Null<FlxCamera>,
    debugLayer:DebugLayer,
    enabledSprites:Array<KissExtendedSprite>,
    selectedSprites:Array<KissExtendedSprite>,
    firstCorner:Null<FlxPoint>,
    secondCorner:Null<FlxPoint>
};

/**
 * Added automatically when you call enableDragToSelect() on a KissExtendedSprite.
 */
class DragToSelectPlugin extends FlxBasic {
    var dragStates:Map<FlxState,DragState> = [];

    public function new() {
        super();
    }

    public function clearEnabledSprites(?state:FlxState) {
        if (state == null) state = FlxG.state;
        dragStates[state].enabledSprites = [];
        dragStates[state].selectedSprites = [];
    }

    // Don't use this on a whole list of sprites! It will be O(N^2)
    public function disableSprite(s: KissExtendedSprite, ?state:FlxState) {
        if (state == null) state = FlxG.state;
        dragStates[state].enabledSprites.remove(s);
        dragStates[state].selectedSprites.remove(s);
    }

    public function enableSprite(s:KissExtendedSprite, ?state:FlxState, ?camera:FlxCamera) {
        if (state == null) state = FlxG.state;
        if (!dragStates.exists(state)) {
            dragStates[state] = {
                camera: camera,
                debugLayer: new DebugLayer(),
                enabledSprites: [s],
                selectedSprites: [],
                firstCorner: null,
                secondCorner: null
            };
            if (camera == null) camera = FlxG.camera;
            dragStates[state].debugLayer.cameras = [camera];
            state.add(dragStates[state].debugLayer);
        } else {
            dragStates[state].enabledSprites.push(s);
        }
    }

    public function selectedSprites() {
        return dragStates[FlxG.state].selectedSprites;
    }
    
    public function deselectSprites() {
        for (sprite in dragStates[FlxG.state].selectedSprites) {
            if (sprite.onDeselected != null) {
                sprite.onDeselected();
            }
        }
        dragStates[FlxG.state].selectedSprites = [];
    }

    var wasJustPressed = false;
    public static var boxColor = FlxColor.LIME;

    public override function update(elapsed:Float) {
        if (dragStates.exists(FlxG.state)) {
            var dragState = dragStates[FlxG.state];
            dragState.debugLayer.clear();

            var camera = dragState.camera;
            if (camera == null) camera = FlxG.camera;

            // If FlxMouseControl has a mouseZone enabled, respect it
            var mousePos = FlxG.mouse.getWorldPosition(camera);
            if (FlxMouseControl.mouseZone != null && !FlxMouseControl.mouseZone.containsPoint(mousePos)) {
                dragState.firstCorner = null;
                dragState.secondCorner = null;
                return;
            }

            // have to skip a frame after justPressed, so KissExtendedSprites
            // can get first access to the mouse input
            if (FlxMouseControl.dragTarget == null) {
                if (wasJustPressed && FlxMouseControl.clickTarget == null) {
                    deselectSprites();
                    dragState.firstCorner = mousePos;
                } 
                dragState.secondCorner = mousePos;
                if (dragState.firstCorner != null && dragState.selectedSprites.length == 0) {
                    var rounded1 = dragState.firstCorner.copyTo();
                    var rounded2 = dragState.secondCorner.copyTo();
                    for (r in [rounded1, rounded2]) {
                        r.x = Std.int(r.x);
                        r.y = Std.int(r.y);
                    }
                    var rect = new FlxRect().fromTwoPoints(rounded1, rounded2);
                    if (FlxG.mouse.justReleased && dragState.selectedSprites.length == 0) {
                        dragState.firstCorner = null;
                        for (s in dragState.enabledSprites) {
                            if (s.scale.x != 1 || s.scale.y != 1) {
                                throw "DragToSelectPlugin can't handle scaled sprites yet!";
                            }
                            var intersection = s.getRotatedBounds().intersection(rect);
                            if (!intersection.isEmpty) {
                                // TODO if pixel perfect is true, get the pixels in the intersection and hit test them for transparency
                                var pixelPerfectCheck = false;
                                if (s.pixelPerfectDrag()) {
                                    var alpha = s.pixelPerfectAlpha();
                                    s.updateFramePixels();
                                    var intersectionInFrame = new Rectangle(Std.int(intersection.x - s.x), Std.int(intersection.y - s.y), Math.min(s.framePixels.width, Std.int(intersection.width)), Math.min(s.framePixels.height, Std.int(intersection.height)));
                                    var pixels = s.framePixels.getPixels(intersectionInFrame);
                                    while (pixels.bytesAvailable > 0) {
                                        var color:FlxColor = pixels.readUnsignedInt();
                                        if (color.alpha * s.alpha >= alpha) {
                                            pixelPerfectCheck = true;
                                            break;
                                        }
                                    }
                                } else {
                                    pixelPerfectCheck = true;
                                }
                                if (pixelPerfectCheck) {
                                    dragState.selectedSprites.push(s);
                                }
                            }
                        }
                        for (s in dragState.selectedSprites) {
                            if (s.onSelected != null) {
                                s.onSelected();
                            }
                        }
                    } else if (!rect.isEmpty) {
                        dragState.debugLayer.drawFlxRect(rect, boxColor);
                    }
                }
            }
            wasJustPressed = FlxG.mouse.justPressed;
        }
    }
}