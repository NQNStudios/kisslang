package;

class PlaygroundEntries extends Control {
    
    public var currentFocus:EntryPanel = null;
    public var currentFocusZ = Mathf.NA_N;
    var ui:GodotUI = null;

    public override function _Ready() {
        var rootNode:RootNode = cast(getParent().getParent().getParent());
        ui = rootNode.ui;
    }

    public override function getDragData(position:Vector2) {
        return currentFocus;
    }

    public override function canDropData(position:Vector2, data:Dynamic) {
        return data != null;
    }
        
    public override function dropData(position:Vector2, data:Dynamic):Void {
        var data:EntryPanel = cast(data);
        data.rectPosition = position;
        ui.playgroundSystem().savePosition(data.e, position.x, position.y, data.z);
    }
}
