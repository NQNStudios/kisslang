package;

using StringTools;
import flash.display.BitmapData;
import haxe.io.Path;
import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.math.FlxRandom;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.geom.ColorTransform;
import flixel.util.FlxSpriteUtil;
using flixel.util.FlxSpriteUtil;
import flixel.util.FlxSave;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.addons.display.FlxExtendedSprite;
import flixel.addons.plugin.FlxMouseControl;
import flixel.addons.ui.FlxInputText;
import kiss.Prelude;
import kiss.List;
import kiss_tools.FlxKeyShortcutHandler;
import HabitModel;
import sys.FileSystem;
import hx.strings.Strings;
import datetime.DateTime;
import flixel.ui.FlxButton;
using kiss_flixel.CameraTools;
using kiss_flixel.GroupTools;
using kiss_flixel.DebugLayer;
import kiss_flixel.KissExtendedSprite;
import kiss_flixel.SimpleWindow;
import haxe.ds.Option;
import jigsawx.JigsawPiece;
import jigsawx.Jigsawx;
import jigsawx.math.Vec2;
import kiss_flixel.DragToSelectPlugin;

typedef StartPuzzleFunc = (Int, Int) -> Void;

@:build(kiss.Kiss.build())
class HabitState extends FlxState {
    public function drawPieceShape( surface: FlxSprite, jig: JigsawPiece, scale:Float, fillColor: FlxColor, ?outlineColor: FlxColor)
    {
        if (outlineColor == null) outlineColor = fillColor;
        var points = [for (point in jig.getPoints()) new FlxPoint(point.x / scale + ROT_PADDING, point.y / scale + ROT_PADDING)];
        points.push(points[0]);
        FlxSpriteUtil.drawPolygon(
            surface, 
            points,
            fillColor, 
            {
                thickness: 1,
                color: outlineColor
            });
    }
}
