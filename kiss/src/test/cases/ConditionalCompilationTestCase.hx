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
}
