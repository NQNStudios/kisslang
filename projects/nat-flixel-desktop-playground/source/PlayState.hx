package;

import kiss.Prelude;
import kiss.List;
import sys.FileSystem;
import nat.Entry;
import nat.BoolExpInterp;
import nat.Archive;
import nat.ArchiveUI;
import nat.ArchiveController;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUIPopup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
using flixel.util.FlxSpriteUtil;
import flixel.FlxCamera;
import flixel.math.FlxRect;
import flixel.addons.plugin.FlxMouseControl;
import flixel.input.mouse.FlxMouseEventManager;
using StringTools;
using kiss_flixel.DebugLayer;
using kiss_flixel.CameraTools;
using kiss_flixel.SimpleWindow;
import kiss_tools.KeyShortcutHandler;
import kiss_tools.FlxKeyShortcutHandler;
import nat.systems.PlaygroundSystem;
import flash.desktop.Clipboard;
import flash.desktop.ClipboardFormats;
import haxe.ds.Option;
import nat.components.Position;

@:build(kiss.Kiss.build())
class PlayState extends FlxState implements ArchiveUI {}
