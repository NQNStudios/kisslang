package nat;

import nat.ArchiveController;

interface ArchiveUI {
    /**
     * Prompt the user to enter text
     */
    function enterText(?minLength:Int, ?maxLength:Int):String;

    /**
     * Prompt the user to enter a number
     */
    function enterNumber(?min:Float, ?max:Float, ?inStepsOf:Float):Float;

    /**
     * Prompt the user to choose a single Entry
     */
    function chooseEntry(archive:Archive):Entry;

    /**
     * Prompt the user to choose multiple Entries
     */
    function chooseEntries(archive:Archive, ?min:Int, ?max:Int):Array<Entry>;

    /**
     * Update the interface to reflect changes made to Entries through commands
     */
    function handleChanges(changeSet:ChangeSet):Void;
}