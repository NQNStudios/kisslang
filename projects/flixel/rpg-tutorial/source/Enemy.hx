package;

import flixel.FlxObject;
import flixel.FlxSprite;

enum EnemyType
{
	REGULAR;
	BOSS;
}

@:build(kiss.Kiss.build("source/Enemy.kiss"))
class Enemy extends FlxSprite {}
