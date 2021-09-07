package test;

import nat.*;
import nat.ArchiveController.ChangeSet;

class DummyUI implements ArchiveUI {
    var controller:ArchiveController = null;

    public function new() {}

    public function setController(controller:ArchiveController) {
        this.controller = controller;
    }

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

    public function handleChanges(archive:Archive, changeSet:ChangeSet) {}

    public function displayMessage(message:String) {}

    public function reportError(error:String) {}
}
