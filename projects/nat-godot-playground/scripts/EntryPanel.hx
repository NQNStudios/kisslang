package;

class EntryPanel extends PanelContainer {
    public var z:Single = 0;
    public var e:Entry = null;
    var parent:PlaygroundEntries = null;

    public override function _Ready() {
        parent = cast(getParent());
    }

    public function _on_EntryPanel_mouse_entered() {
        var currentFocusZ = parent.currentFocusZ;
        if (Mathf.isNaN(currentFocusZ) || currentFocusZ <= this.z) {
            parent.currentFocus = this;
            parent.currentFocusZ = this.z;
        }
    }
    
    public function _on_EntryPanel_mouse_exited() {
        if (parent.currentFocus == this) {
            parent.currentFocus = null;
            parent.currentFocusZ = Mathf.NA_N;
        }
    }
}
