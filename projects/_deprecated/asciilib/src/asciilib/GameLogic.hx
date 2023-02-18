package asciilib;

// Your game's logic is an interface contained in Game instead of a class that extends Game.
// This allows ASCIILib to support libraries like HaxeFlixel where your main class is expected
// to extend another class already.
interface GameLogic {
    public function initialize(assets:Assets):Void;
    public function update(game:Game, deltaSeconds:Float):Void;
    public function draw(graphicsHandle:() -> Graphics, assets:Assets):Void;
}
