package kiss_flixel;

import flixel.FlxG;
import flixel.addons.plugin.FlxMouseControl;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxBasic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

typedef DragState = {
    camera:FlxCamera,
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

    public function enableSprite(s:KissExtendedSprite, ?state:FlxState, ?camera:FlxCamera) {
        if (state == null) state = FlxG.state;
        if (camera == null) camera = FlxG.camera;
        if (!dragStates.exists(state)) {
            dragStates[state] = {
                camera: camera,
                debugLayer: new DebugLayer(),
                enabledSprites: [s],
                selectedSprites: [],
                firstCorner: null,
                secondCorner: null
            };
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
        dragStates[FlxG.state].selectedSprites = [];
    }

    public override function update(elapsed:Float) {
        if (dragStates.exists(FlxG.state)) {
            var dragState = dragStates[FlxG.state];
            dragState.debugLayer.clear();

            // Might have to skip a frame after justPressed, so KissExtendedSprites
            // can get first access to the mouse input
            if (FlxMouseControl.dragTarget == null) {
                if (FlxG.mouse.justPressed) {
                    dragState.firstCorner = FlxG.mouse.getWorldPosition(dragState.camera);
                } 
                dragState.secondCorner = FlxG.mouse.getWorldPosition(dragState.camera);
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
                            if (!s.getRotatedBounds().intersection(rect).isEmpty) {
                                // TODO if pixel perfect is true, get the pixels in the intersection and hit test them for transparency
                                dragState.selectedSprites.push(s);
                            }
                        }
                    } else if (!rect.isEmpty) {
                        dragState.debugLayer.drawFlxRect(rect);
                    }
                }
            }
        }
    }
}