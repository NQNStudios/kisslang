package nat;

import nat.ArchiveController;

interface ArchiveUI {
    /**
     * Accept and store a reference to the controller
     */
    function setController(controller:ArchiveController):Void;

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
}
