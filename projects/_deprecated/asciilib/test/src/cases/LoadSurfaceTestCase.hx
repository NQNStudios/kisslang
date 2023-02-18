package cases;

import utest.Test;
import utest.Assert;
import asciilib.GameLogic;
import asciilib.Game;
import asciilib.Graphics;
import asciilib.Colors;
import asciilib.Assets;
import asciilib.Surface;

class LoadSurfaceGameLogic implements GameLogic {
    public function new() {}

    public function initialize(assets:Assets) {
        assets.loadSurface("laptop", "assets/laptop.srf");
    }

    public function update(game:Game, deltaSeconds:Float):Void {}

    public function draw(graphics:Void->Graphics, assets:Assets):Void {}
}

class LoadSurfaceTestCase extends Test {
    function testLoadSurface() {
        var game = Main.newGame(new LoadSurfaceGameLogic());
        var laptop = game.assets.getSurface("laptop");

        var cornerColor = laptop.getBackgroundColor(0, 0);
        Assert.equals(128, cornerColor.r);
        Assert.equals(128, cornerColor.g);
        Assert.equals(255, cornerColor.b);
        Assert.isFalse(laptop.isCellOpaque(0, 0));
        var topColor = laptop.getBackgroundColor(6, 0);
        Assert.equals(41, topColor.r);
        Assert.isTrue(laptop.isCellOpaque(6, 0));
        Assert.equals(".", laptop.getSpecialInfo(0, 0));
        Assert.equals("POINT_screen", laptop.getSpecialInfo(8, 4));
        Assert.equals("t", laptop.getLetter(17, 6).char);
        Assert.equals(" ", laptop.getLetter(18, 6).char);
    }
}
