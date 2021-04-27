package;

import utest.Runner;
import utest.ui.Report;
import asciilib.GameLogic;
import asciilib.Game;
import asciilib.backends.test.*;

class Main {
    public static function newGame(logic:GameLogic) {
        return new Game("Test game", 100, 40, 8, 12, logic, new TestGraphicsBackend());
    }

    static function main() {
        var runner = new Runner();
        runner.addCases(cases);
        Report.create(runner);
        runner.run();
    }
}