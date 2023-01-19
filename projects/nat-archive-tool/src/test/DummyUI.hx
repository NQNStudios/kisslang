package test;

import nat.*;
import nat.systems.PlaygroundSystem;
import nat.components.Position;
import nat.ArchiveController.ChangeSet;
import haxe.ds.Option;
import kiss_tools.KeyShortcutHandler;

class DummyUI implements ArchiveUI {
    public var controller:ArchiveController = null;

    public function new() {}

    public function enterText(prompt:String, resolve:(String) -> Void, maxLength:Float) {
        // TODO for proper testing, this will need to resolve with specific pre-coded strings
        resolve("");
    }

    public function enterNumber(prompt:String, resolve:(Float) -> Void, min:Float, max:Float, ?inStepsOf:Float) {
        // TODO for proper testing, this will need to resolve with specific pre-coded numbers
        resolve(min);
    }

    public function chooseEntry(prompt:String, archive:Archive, resolve:(Entry) -> Void) {
        // TODO for proper testing, this will need to resolve with specific pre-coded entries
        resolve(null);
    }

    public function chooseEntries(prompt:String, archive:Archive, resolve:(Array<Entry>) -> Void, min:Int, max:Float) {
        // TODO for proper testing, this will need to resolve with specific pre-coded entry lists
        resolve([]);
    }

    public function chooseBetweenStrings(prompt:String, choices:Array<String>, resolve:String->Void) {
        resolve(choices[0]);
    }

    public function handleChanges(archive:Archive, changeSet:ChangeSet) {}

    public function displayMessage(message:String) {}

    public function reportError(error:String) {}

    public function onSelectionChanged(selectedEntries:Array<Entry>, lastSelectedEntries:Array<Entry>) {}
    
    public function showPrefixMap(map:Map<String,String>) {}
    public function hidePrefixMap() {}
    public function cursorPosition():Option<Position> {
        return None;
    };
    public function choosePosition(prompt:String, resolve:Position->Void) {
        resolve({x: 0, y: 0, z: 0});
    }
    public function playgroundSystem():Null<PlaygroundSystem> {
        return null;
    }
    public var shortcutHandler:Null<KeyShortcutHandler<Entry>> = null;
}
