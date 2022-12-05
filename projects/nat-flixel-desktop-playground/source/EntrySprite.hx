package;

import kiss.Prelude;
import kiss.List;
import flash.display.BitmapData;
import openfl.display.Sprite;
import format.SVG;
import kiss_flixel.KissExtendedSprite;
import flixel.text.FlxText;
import flixel.util.FlxSpriteUtil;
import nat.Entry;
import nat.Archive;
import nat.ArchiveController;
import nat.BoolExpInterp;
import nat.components.Images;
import nat.components.Position;
import nat.components.Scale;
import sys.io.File;
using kiss_flixel.CameraTools;
using haxe.io.Path;

@:build(kiss.Kiss.build())
class EntrySprite extends KissExtendedSprite {}
