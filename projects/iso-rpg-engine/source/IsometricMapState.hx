package;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import flixel.math.FlxVector;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;

import flash.display.BitmapData;

import kiss.Prelude;
import data.blades.ScenData;

@:build(kiss.Kiss.build())
class IsometricMapState<FloorData, TerrainData, EntityData, ItemData> extends FlxState {}
