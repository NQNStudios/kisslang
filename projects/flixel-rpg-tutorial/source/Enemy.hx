package;

import flixel.FlxObject;
import flixel.FlxSprite;

enum EnemyType
{
	REGULAR;
	BOSS;
}

@:build(kiss.Kiss.build())
class Enemy extends FlxSprite {}
