package test;

import utest.Runner;
import utest.ui.Report;
#if macro
import haxe.macro.Context;
#end

class TestMain {
    public static function main() {
        var runner = new Runner();
        addCases();
        Report.create(runner);
        runner.run();
    }

    static macro function addCases() {
        if (Context.defined("cases")) {
            var cases = Context.definedValue("cases").split(",");
            var block = [];
            for (caseName in cases) {
                var typePath = {
                    pack: ["test", "cases"],
                    name: caseName
                };
                block.push(macro runner.addCase(new $typePath()));
            }
            return macro $b{block};
        } else {
            return macro runner.addCases(test.cases);
        }
    }
}
