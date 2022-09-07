package kiss_flixel;

import kiss.Prelude;
import kiss.List;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import kiss_tools.FlxKeyShortcutHandler;

typedef ShortcutAction = Void->Void;
typedef Action = FlxSprite->Void;

@:build(kiss.Kiss.build())
class SimpleWindow extends FlxSprite {}
