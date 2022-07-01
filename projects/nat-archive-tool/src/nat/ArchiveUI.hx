package nat;

import nat.Entry;
import nat.ArchiveController;
import kiss_tools.KeyShortcutHandler;

interface ArchiveUI {
    /**
     * Reference to the ArchiveController
     */
    var controller(default, default):ArchiveController;

    /**
     * A KeyShortcutHandler that will integrate with the KeyShortcutSystem if provided
     */
    var shortcutHandler(default, null):Null<KeyShortcutHandler<Entry>>;

    /**
     * Prompt the user to enter text
     */
    function enterText(prompt:String, resolve:(String) -> Void, maxLength:Float):Void;

    /**
     * Prompt the user to enter a number
     */
    function enterNumber(prompt:String, resolve:(Float) -> Void, min:Float, max:Float, ?inStepsOf:Float):Void;

    /**
     * Prompt the user to choose a single Entry
     */
    function chooseEntry(prompt:String, archive:Archive, resolve:(Entry) -> Void):Void;

    /**
     * Prompt the user to choose multiple Entries
     */
    function chooseEntries(prompt:String, archive:Archive, resolve:(Array<Entry>) -> Void, min:Int, max:Float):Void;

    /**
     * Update the interface to reflect changes made to Entries through commands
     */
    function handleChanges(archive:Archive, changeSet:ChangeSet):Void;

    /**
     * Tell the user something useful
     */
    function displayMessage(message:String):Void;

    /**
     * Tell the user that something is wrong
     */
    function reportError(error:String):Void;

    /**
     * Update UI to show that the set of selected entries has changed
     */
    function onSelectionChanged(selectedEntries:Array<Entry>, lastSelectedEntries:Array<Entry>):Void;
}
