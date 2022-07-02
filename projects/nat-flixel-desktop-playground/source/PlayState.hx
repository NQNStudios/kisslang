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
using kiss_flixel.CameraTools;
import kiss_tools.KeyShortcutHandler;
import kiss_tools.FlxKeyShortcutHandler;
import nat.systems.PlaygroundSystem;

@:build(kiss.Kiss.build())
class PlayState extends FlxState implements ArchiveUI {}
