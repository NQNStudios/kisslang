package asciilib;

interface GameLogic {
    public function update(deltaSeconds:Float):Void;
    public function draw(graphicsHandle:() -> Graphics):Void;
}
