package;

import sys.io.File;
import sys.FileSystem;
import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;
import flixel.util.FlxTimer;
import kiss.Prelude;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, HabitState, 1, 60, 60, true));
		var t:HabitState = cast FlxG.state;
		
		var saveFolder = Prelude.joinPath(Prelude.userHome(), "Documents", "HabitPuzzles");
		var habitFile = Prelude.joinPath(saveFolder, "habits.txt");
		if (!(FileSystem.exists(saveFolder) && FileSystem.isDirectory(saveFolder))) {
			FileSystem.createDirectory(saveFolder);
			File.saveContent(habitFile, File.getContent("habits/default.txt"));
		}

		var habitFile = if (Sys.args().length > 0 && Sys.args()[0].length > 0) {
			 Sys.args()[0];
		} else {
			habitFile;
		};
		function reloadModel(_) {
			if (t.draggingSprite == null) {
				t.refreshModel(new HabitModel(habitFile));
				t.model.save();
			}
		}
		t.setModel(new HabitModel(habitFile));
		new FlxTimer().start(30, reloadModel, 0);

	}

}
