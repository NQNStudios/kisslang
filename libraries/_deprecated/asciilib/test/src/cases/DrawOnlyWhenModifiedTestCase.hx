package cases;

import utest.Test;
import utest.Assert;
import asciilib.GameLogic;
import asciilib.Game;
import asciilib.Graphics;
import asciilib.Colors;
import asciilib.Assets;
import asciilib.backends.test.TestGraphicsBackend;

class DrawOnlyWhenModifiedGameLogic implements GameLogic {
    var firstDraw = true;

    public function new() {}

    public function initialize(assets:Assets) {}

    public function update(game:Game, deltaSeconds:Float):Void {}

    public function draw(graphics:Void->Graphics, assets:Assets):Void {
        if (firstDraw) {
            graphics().setLetter(0, 0, {char: "@", color: Colors.Red});
            firstDraw = false;
        }
    }
}

class DrawOnlyWhenModifiedTestCase extends Test {
    function testDrawOnlyWhenModified() {
        var game = Main.newGame(new DrawOnlyWhenModifiedGameLogic());
        var graphicsBackend:TestGraphicsBackend = cast game.graphicsBackend;
        game.draw();
        Assert.equals("@", game.graphics.getLetter(0, 0).char);
        Assert.equals(1, graphicsBackend.drawCalled);
        game.draw();
        Assert.equals(1, graphicsBackend.drawCalled);
    }
}
