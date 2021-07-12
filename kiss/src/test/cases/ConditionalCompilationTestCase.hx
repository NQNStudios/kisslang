package test.cases;

import utest.Assert;
import utest.Test;
import kiss.Prelude;

@:build(kiss.Kiss.build())
class ConditionalCompilationTestCase extends Test {
    function testIf() {
        #if interp
        Assert.isTrue(runningInHaxe);
        #else
        Assert.isFalse(runningInHaxe);
        #end

        #if (py || js)
        Assert.isTrue(runningInPyOrJs);
        #end
    }

    function testWhen() {
        #if interp
        Assert.equals(6, number());
        #else
        Assert.equals(5, number());
        #end
    }

    function testUnless() {
        #if !interp
        Assert.equals(9, number2());
        #else
        Assert.equals(12, number2());
        #end
    }

    function testCond() {
        #if cpp
        Assert.equals("C++", targetLanguage);
        #elseif interp
        Assert.equals("Haxe", targetLanguage);
        #elseif hxnodejs
        Assert.equals("NodeJS", targetLanguage);
        #elseif js
        Assert.equals("JavaScript", targetLanguage);
        #elseif python
        Assert.equals("Python", targetLanguage);
        #end
    }

    function testCase() {
        _testCase();
    }
}
