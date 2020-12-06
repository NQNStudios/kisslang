package test;

import utest.Runner;
import utest.ui.Report;

class TestMain {
    public static function main() {
        var runner = new Runner();
        runner.addCases(test.cases);
        Report.create(runner);
        runner.run();
    }
}
