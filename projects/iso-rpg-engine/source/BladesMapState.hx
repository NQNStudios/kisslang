package;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.math.FlxRect;
import flixel.math.FlxVector;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.input.mouse.FlxMouseEventManager;

import flash.display.BitmapData;

import kiss.Prelude;
import data.blades.ScenData;
import data.blades.Scenario;
import data.blades.SpriteSheet;
import data.blades.TileMap;

using kiss_flixel.CameraTools;

@:build(kiss.Kiss.build())
class BladesMapState extends FlxState {}
