package nat;

import uuid.Uuid;

@:jsonParse(function (json) return new nat.Entry(json.id, json.components, json.files))
class Entry {
    public var id:String;
    public var components:Map<String, String> = [];
    public var files:Array<FileRef> = [];
    function toString() {
        return if (components.exists("Name")) components["Name"] else 'entry $id';
    }
    public function new(?id:String, ?components:Map<String,String>, ?files:Array<String>) {
        this.id = if (id != null) id else Uuid.v4();
        if (components != null) this.components = components;
        if (files != null) this.files = files;
    }
}
