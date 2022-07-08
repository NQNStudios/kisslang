package;

import flash.display.BitmapData;
import haxe.io.Path;
import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.math.FlxRandom;
import flixel.math.FlxPoint;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.geom.ColorTransform;
import flixel.util.FlxSpriteUtil;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.addons.display.FlxExtendedSprite;
import flixel.addons.plugin.FlxMouseControl;
import kiss.Prelude;
import kiss.List;
import kiss_tools.FlxKeyShortcutHandler;
import HabitModel;
import hx.strings.Strings;
import datetime.DateTime;

import jigsawx.JigsawPiece;
import jigsawx.Jigsawx;
import jigsawx.math.Vec2;

@:build(kiss.Kiss.build())
class HabitState extends FlxState {
    public function drawPieceShape( surface: FlxSprite, jig: JigsawPiece, c: FlxColor )
    {
        var points = [for (point in jig.getPoints()) new FlxPoint(jig.xy.x + point.x, jig.xy.y + point.y)];
        points.push(points[0]);
        FlxSpriteUtil.drawPolygon(
            surface, 
            points,
            c);
    }
}
