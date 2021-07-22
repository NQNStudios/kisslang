package test.cases;

import utest.Test;
import utest.Assert;
import kiss.Prelude;
import kiss.List;
import haxe.ds.Option;

using StringTools;

@:build(kiss.Kiss.build())
class MacroTestCase extends Test {
    function testMultipleFieldForms() {
        Assert.equals(5, myVar);
        Assert.equals(6, myFunc());
    }

    function testExpandList() {
        Assert.equals(6, sum1());
        Assert.equals(6, sum2());
    }

    function testModularMacros() {
        Assert.equals("Nat 5", nameAndNumber("Nat", 5));
    }

    function testUndefAlias() {
        Assert.equals(9, print);
        Assert.equals(9, aliasValue());
    }
}
